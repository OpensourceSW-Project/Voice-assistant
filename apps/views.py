from rest_framework.views import APIView
from rest_framework import status
from rest_framework.response import Response
from django.conf import settings
from django.db.models import Avg
from apps.serializers import ReservationSerializer, AccommodationSerializer, ReviewSerializer, HotelRouteResponseSerializer
from apps.models import Reservation, Accommodation, User, Review
from django.core.paginator import Paginator, EmptyPage
from datetime import datetime
from transformers import AutoTokenizer, AutoModelForSequenceClassification
from decimal import Decimal
import torch
from geopy.distance import geodesic
from sklearn.preprocessing import MinMaxScaler
import pandas as pd
import googlemaps
from konlpy.tag import Okt
import requests
import os

MODEL_PATH = '/home/ubuntu/project/OpenSWAIModel/Voice-assistant/finetuned_model_v4'
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = AutoModelForSequenceClassification.from_pretrained(MODEL_PATH).to(device)
tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH)

class UserReservationInfo(APIView):
    # 유저 예약 정보 조회
    def get(self, request, format=None):
        user_id = request.query_params.get('user_id')

        if not user_id: # user_id를 query_params에 안넣었을 때
            return Response({"error": "user_id required"}, status=status.HTTP_400_BAD_REQUEST)

        reservations = Reservation.objects.filter(user_id=user_id)

        if not reservations.exists(): # user가 없을 때
            return Response({"message": "not found user"}, status=status.HTTP_404_NOT_FOUND)

        serializer = ReservationSerializer(reservations, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


    # 유저 예약 생성
    def post(self, request):
        user_id = request.data.get('user_id')
        accommodation_name = request.data.get('accommodation_name')
        check_in_date = request.data.get('check_in_date')
        check_out_date = request.data.get('check_out_date')
        price = request.data.get('price', 0)

        if not user_id or not accommodation_name or not check_in_date or not check_out_date:
            return Response({"error": "user_id, accommodation_name, check_in_date, check_out_date required"},
                            status=status.HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.get(id=user_id)
            accommodation = Accommodation.objects.get(name=accommodation_name)
        except User.DoesNotExist:
            return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
        except Accommodation.DoesNotExist:
            return Response({"error": "Accommodation not found"}, status=status.HTTP_404_NOT_FOUND)

        try:
            reservation = Reservation.objects.create(
                user=user,
                accommodation=accommodation,
                check_in_date=check_in_date,
                check_out_date=check_out_date,
                status=True,
                price=price,
                create_at=datetime.now().date(),
                updated_at=datetime.now().date(),
            )

            return Response({"message": "Reservation successfully"}, status=status.HTTP_201_CREATED)

        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        # 유저 예약 삭제
    def delete(self, request):
        user_id = request.data.get('user_id')  # 사용자 ID
        accommodation_name = request.data.get('accommodation_name')  # 숙소 이름

        if not user_id or not accommodation_name:
            return Response(
                {"error": "user_id and accommodation_name are required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            accommodation = Accommodation.objects.get(name=accommodation_name)
            reservation = Reservation.objects.filter(user_id=user_id, accommodation=accommodation).first()
            if not reservation:
                return Response({"error": "Reservation not found"}, status=status.HTTP_404_NOT_FOUND)

            reservation.delete()
            return Response({"message": "Reservation deleted successfully"}, status=status.HTTP_200_OK)

        except Accommodation.DoesNotExist:
            return Response({"error": "Accommodation not found"}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class AccommodationInfo(APIView):
    # 숙소 정보 조회
    def get(self, request, format=None):
        # 예시 : api/accommodation-info/?accomodation_name=OO호텔
        accommodation_name = request.query_params.get('accommodation_name')
        page = int(request.query_params.get('page', 1))
        page_size = int(request.query_params.get('page_size', 10))

        # 파라미터에 숙소 이름을 넣으면 그 숙소만 검색
        if accommodation_name:
            accommodation = Accommodation.objects.filter(name__icontains=accommodation_name)

        # 예시 : api/accommodation-info/
        # 아니면 모든 숙소 정보 검색
        else:
            accommodation = Accommodation.objects.all().order_by('id')

        paginator = Paginator(accommodation, page_size)

        try:
            paginated_accommodations = paginator.page(page)
        except EmptyPage:
            return Response({"error": "Page not found"}, status=status.HTTP_404_NOT_FOUND)

        serializer = AccommodationSerializer(paginated_accommodations, many=True)
        response_data = {
            "accommodations": serializer.data,
            "total_pages": paginator.num_pages,
            "current_page": int(page),
            "page_size": int(page_size),
            "total_accommodations": paginator.count,
        }

        return Response(response_data, status=status.HTTP_200_OK)

class ReviewInfo(APIView):
    def get(self, request, format=None):
        accommodation_name = request.query_params.get('accommodation_name')
        page = int(request.query_params.get('page', 1))
        page_size = int(request.query_params.get('page_size', 10))

        if accommodation_name:
            try:
                accommodation = Accommodation.objects.get(name=accommodation_name)
            except Accommodation.DoesNotExist:
                return Response({"error": "Accommodation not found"}, status=status.HTTP_404_NOT_FOUND)

            reviews = Review.objects.filter(accommodation=accommodation).order_by('-created_at')
            paginator = Paginator(reviews, page_size)

            try:
                paginated_reviews = paginator.page(page)
            except EmptyPage:
                return Response({"error": "Page not found"}, status=status.HTTP_404_NOT_FOUND)

            serializer = ReviewSerializer(paginated_reviews, many=True)
            response_data = {
                "reviews": serializer.data,
                "total_pages": paginator.num_pages,
                "current_page": int(page),
                "page_size": int(page_size),
                "total_reviews": paginator.count,
            }

            return Response(response_data, status=status.HTTP_200_OK)

        else:
            return Response({"error": "not found accommodation name"})


    # 리뷰 추가 및 rank 업데이트
    def post(self, request, format=None):
        accommodation_name = request.data.get('accommodation_name')
        content = request.data.get('content')
        rank = request.data.get('rank')

        if not accommodation_name or not content or not rank:
            return Response({"error": "Accommodation name, content, and rank are required"},
                            status=status.HTTP_400_BAD_REQUEST)

        try:
            accommodation = Accommodation.objects.get(name=accommodation_name)
        except Accommodation.DoesNotExist:
            return Response({"error": "Accommodation not found"}, status=status.HTTP_404_NOT_FOUND)

        # 새로운 리뷰 추가
        Review.objects.create(
            accommodation=accommodation,
            content=content,
            rank=rank,
            created_at=datetime.now()
        )

        # 별점 업데이트
        avg_rank = Review.objects.filter(accommodation=accommodation).aggregate(Avg('rank'))['rank__avg']
        accommodation.ranks = round(avg_rank, 2) if avg_rank else 0.0
        accommodation.save()

        return Response({"message": "Review added successfully"}, status=status.HTTP_201_CREATED)

    def delete(self, request, format=None):
        review_id = request.data.get('review_id')

        if not review_id:
            return Response({"error": "review_id is required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            review = Review.objects.get(id=review_id)
        except Review.DoesNotExist:
            return Response({"error": "Review not found"}, status=status.HTTP_404_NOT_FOUND)

        # 리뷰 삭제
        review.delete()

        return Response({"message": "Review deleted successfully"}, status=status.HTTP_200_OK)


class LikeAccommodation(APIView):
    def get(self, request, format=None):
        user_id = request.query_params.get('user_id')

        if not user_id:
            return Response({"error": "user_id required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)

        liked_list = user.likes.all()
        serializer = AccommodationSerializer(liked_list, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request, format=None):
        user_id = request.data.get('user_id')
        accommodation_name = request.data.get('accommodation_name')

        if not user_id or not accommodation_name:
            return Response({"error": "user_id and accommodation_name required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.get(id=user_id)
            accommodation = Accommodation.objects.get(name=accommodation_name)
        except User.DoesNotExist:
            return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
        except Accommodation.DoesNotExist:
            return Response({"error": "Accommodation not found"}, status=status.HTTP_404_NOT_FOUND)

        accommodation.like.add(user)
        return Response({"message": "Like added successfully"}, status=status.HTTP_200_OK)

    def delete(self, request, format=None):
        user_id = request.data.get('user_id')
        accommodation_name = request.data.get('accommodation_name')

        if not user_id or not accommodation_name:
            return Response({"error": "user_id and accommodation_name required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.get(id=user_id)
            accommodation = Accommodation.objects.get(name=accommodation_name)
        except User.DoesNotExist:
            return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
        except Accommodation.DoesNotExist:
            return Response({"error": "Accommodation not found"}, status=status.HTTP_404_NOT_FOUND)

        if accommodation.like.filter(id=user.id).exists():
            accommodation.like.remove(user)
            return Response({"message": "Like removed successfully"}, status=status.HTTP_200_OK)
        else:
            return Response({"message": "Like not found for this user"}, status=status.HTTP_404_NOT_FOUND)


# GPT 사용, 프롬포트 : AI코드와 내 백엔드 코드를 합쳐줘
class AISet(APIView):
    def post(self, request):
        """
        숙소 추천 API
        POST 요청으로 사용자의 위치와 조건을 받아 추천 숙소를 반환합니다.
        """
        try:
            voice_text = request.data.get("voice_text")  # 사용자의 음성 텍스트
            max_distance = request.data.get("max_distance", 50)  # 최대 거리 (기본값: 50km)
            default_location = (36.3504, 127.3845)  # 기본 위치: 대전

            if not voice_text:
                return Response({"error": "voice_text is required"}, status=status.HTTP_400_BAD_REQUEST)

            # 음성 텍스트에서 위치 추출
            user_location = self.extract_location(voice_text)  # 메서드 이름 수정

            # 호텔 데이터 로드
            accommodations = Accommodation.objects.all().values(
                "id", "name", "price", "latitude", "longitude", "ranks"
            )
            accommodation_list = [
                {
                    "id": acc["id"],
                    "name": acc["name"],
                    "price": float(acc["price"]) if isinstance(acc["price"], Decimal) else acc["price"],
                    "latitude": float(acc["latitude"]) if isinstance(acc["latitude"], Decimal) else acc["latitude"],
                    "longitude": float(acc["longitude"]) if isinstance(acc["longitude"], Decimal) else acc["longitude"],
                    "ranks": float(acc["ranks"]) if isinstance(acc["ranks"], Decimal) else acc["ranks"],
                }
                for acc in accommodations
            ]
            accommodation_df = pd.DataFrame(accommodation_list)

            if accommodation_df.empty:
                return Response({"error": "No accommodations found"}, status=status.HTTP_404_NOT_FOUND)

            # 거리 계산
            accommodation_df["distance"] = accommodation_df.apply(
                lambda row: geodesic(
                    (row["latitude"], row["longitude"]),
                    (user_location[0], user_location[1])
                ).km,
                axis=1,
            )

            # 거리 필터링
            accommodation_df = accommodation_df[accommodation_df["distance"] <= max_distance]
            if accommodation_df.empty:
                return Response({"error": "No accommodations within the specified distance"},
                                status=status.HTTP_404_NOT_FOUND)

            # 정규화 및 점수 계산
            scaler = MinMaxScaler()
            accommodation_df["distance_score"] = scaler.fit_transform(
                1 / (accommodation_df["distance"] + 1).values.reshape(-1, 1))
            accommodation_df["price_score"] = scaler.fit_transform(
                1 / (accommodation_df["price"] + 1).values.reshape(-1, 1))
            accommodation_df["final_score"] = (
                    0.4 * accommodation_df["distance_score"] +
                    0.3 * accommodation_df["ranks"] +
                    0.2 * accommodation_df["distance_score"] +
                    0.1 * accommodation_df["price_score"]
            )

            # 상위 10개 호텔 추천
            recommended_hotels = accommodation_df.sort_values("final_score", ascending=False).head(10)
            hotel_names = recommended_hotels["name"].tolist()
            hotels = Accommodation.objects.filter(name__in=hotel_names)

            if not hotels.exists():
                return Response({"message": "No recommended hotels found"}, status=status.HTTP_404_NOT_FOUND)

            serializer = AccommodationSerializer(hotels, many=True)
            return Response({"recommended_hotels": serializer.data}, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def extract_location(self, voice_text):
        """
        음성 텍스트에서 키워드(지역명) 추출
        """
        # 간단한 키워드 매칭 (예: 대전 지역 기반 키워드)
        okt = Okt()

        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        file_path = os.path.join(base_dir, "dajeon_coordinates.csv")

        daejeon_locations = pd.read_csv(file_path)

        # 음성 텍스트에서 명사 추출
        tokens = okt.nouns(voice_text)
        locations = [word for word in tokens if "동" in word or "구" in word]

        default_location = (36.3504, 127.3845)

        # 대전 지역 매핑
        for loc in locations:
            if "구" in loc:
                clean_loc = loc.rstrip("구")
                matching = daejeon_locations[daejeon_locations["District"].str.contains(clean_loc)]
            elif "동" in loc:
                clean_loc = loc.rstrip("동")
                matching = daejeon_locations[daejeon_locations["Area"].str.contains(clean_loc)]

            if not matching.empty:
                location_row = matching.iloc[0]
                return (location_row["Latitude"], location_row["Longitude"])

        # 위치를 추출하지 못하면 기본 위치 반환
        return default_location

# GPT 사용, 프롬포트 : AI코드와 내 백엔드 코드를 합쳐줘
class RouteRecommendationAPIView(APIView):
    """
    경로 추천 API
    """
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Google Maps Client 초기화
        self.gmaps = googlemaps.Client(key=settings.GMAPS_API_KEY)

        # Naver Maps API 초기화
        self.naver_url = "https://naveropenapi.apigw.ntruss.com/map-direction-15/v1/driving"
        self.naver_headers = {
            "X-NCP-APIGW-API-KEY-ID": settings.NAVER_CLIENT_ID,
            "X-NCP-APIGW-API-KEY": settings.NAVER_CLIENT_SECRET,
        }

    def post(self, request):
        try:
            user_location = request.data.get("user_location")
            hotel_name = request.data.get("hotel_name")

            if not user_location or not hotel_name:
                return Response(
                    {"error": "user_location and hotel_name are required"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            # 호텔 이름으로 DB에서 검색
            try:
                hotel = Accommodation.objects.get(name__icontains=hotel_name)  # 대소문자 무시 검색
            except Accommodation.DoesNotExist:
                return Response({"error": "Hotel not found"}, status=status.HTTP_404_NOT_FOUND)

            # 호텔의 위도와 경도 변환 (필요한 경우)
            if not hotel.latitude or not hotel.longitude:
                hotel.latitude, hotel.longitude = self.get_lat_lng_from_address(hotel.address)
                if not hotel.latitude or not hotel.longitude:
                    return Response(
                        {"error": "Unable to retrieve geolocation for the hotel address"},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    )
                hotel.save()  # 변환된 좌표를 DB에 저장

            # 경로 계산
            transit_time = self.get_transit_time(user_location, (hotel.latitude, hotel.longitude))
            car_time = self.get_car_time(user_location, (hotel.latitude, hotel.longitude))

            # 응답 데이터 생성
            response_data = {
                "name": hotel.name,
                "address": hotel.address,
                "latitude": hotel.latitude,
                "longitude": hotel.longitude,
                "transit_time": transit_time,
                "car_time": car_time,
            }

            return Response(response_data, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def get_lat_lng_from_address(self, address):
        """
        Google Maps Geocoding API를 사용하여 주소를 위도와 경도로 변환
        """
        try:
            geocode_result = self.gmaps.geocode(address)
            if geocode_result:
                location = geocode_result[0]['geometry']['location']
                return location['lat'], location['lng']
            return None, None
        except Exception as e:
            print(f"Geocoding error: {e}")
            return None, None

    def get_transit_time(self, start_location, end_location):
        """
        Google Maps Distance Matrix API를 사용하여 대중교통 이동 시간 계산
        """
        try:
            start = f"{start_location[0]},{start_location[1]}"
            end = f"{end_location[0]},{end_location[1]}"
            result = self.gmaps.distance_matrix(start, end, mode="transit", departure_time=datetime.now())
            duration = result['rows'][0]['elements'][0].get('duration', {}).get('text', "Not available")
            return duration
        except Exception as e:
            print(f"Transit time error: {e}")
            return "Error calculating transit time"

    def get_car_time(self, start_location, end_location):
        """
        Naver Maps API를 사용하여 자동차 이동 시간 계산
        """
        try:
            start = f"{start_location[1]},{start_location[0]}"  # Naver는 경도, 위도 순서
            end = f"{end_location[1]},{end_location[0]}"
            params = {"start": start, "goal": end, "option": "trafast"}  # 실시간 빠른 길
            response = requests.get(self.naver_url, headers=self.naver_headers, params=params)

            if response.status_code == 200:
                result = response.json()
                duration = result.get("route", {}).get("trafast", [{}])[0].get("summary", {}).get("duration", None)
                if duration is not None:
                    return f"{round(duration / 60000)} minutes"  # 밀리초 -> 분
            return "Not available"
        except Exception as e:
            print(f"Car time error: {e}")
            return "Error calculating car time"