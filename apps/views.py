from rest_framework.views import APIView
from rest_framework import status
from rest_framework.response import Response
from django.db.models import Avg
from apps.serializers import ReservationSerializer, AccommodationSerializer, ReviewSerializer
from apps.models import Reservation, Accommodation, User, Review
from django.core.paginator import Paginator, EmptyPage
from datetime import datetime
# from transformers import AutoTokenizer, AutoModelForSequenceClassification
# import torch
# from geopy.distance import geodesic
# from sklearn.preprocessing import MinMaxScaler
import pandas as pd


# 숙소 정보 조회 GET(완)

# 좋아요 기능 GET, POST, DELETE(완)

# 추후
# 사용자 예약 정보 조회, 생성
# POST Request
# user_id, check_in_date, check_out_date, status, price, create_at, updated_at, ranks
# GET Response
# reservation, user_id, check_in_date, check_out_date, status, price, create_at, updated_at, ranks

# AI 연결


# class UserReservationInfo(APIView):
#     # 유저 예약 정보 조회
#     def get(self, request, format=None):
#         user_id = request.query_params.get('user_id')
#
#         if not user_id: # user_id를 query_params에 안넣었을 때
#             return Response({"error": "user_id required"}, status=status.HTTP_400_BAD_REQUEST)
#
#         reservations = Reservation.objects.filter(user_id=user_id)
#
#         if not reservations.exists(): # user가 없을 때
#             return Response({"message": "not found user"}, status=status.HTTP_404_NOT_FOUND)
#
#         serializer = ReservationSerializer(reservations, many=True)
#         return Response(serializer.data, status=status.HTTP_200_OK)
#
#     # 유저 예약 생성
#     def post(self, request):
#         user_id = request.data.get('user_id')
#         accommodation_name = request.data.get('accommodation_name')
#         check_in_date = request.data.get('check_in_date')
#         check_out_date = request.data.get('check_out_date')
#         price = request.data.get('price', 0)
#
#         if not user_id or not accommodation_name or not check_in_date or not check_out_date:
#             return Response({"error": "user_id, accommodation_name, check_in_date, check_out_date required"},
#                             status=status.HTTP_400_BAD_REQUEST)
#
#         try:
#             user = User.objects.get(id=user_id)
#             accommodation = Accommodation.objects.get(name=accommodation_name)
#         except User.DoesNotExist:
#             return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
#         except Accommodation.DoesNotExist:
#             return Response({"error": "Accommodation not found"}, status=status.HTTP_404_NOT_FOUND)
#
#             # 예약 생성
#         try:
#             reservation = Reservation.objects.create(
#                 user=user,
#                 accomodation=accommodation,
#                 check_in_date=check_in_date,
#                 check_out_date=check_out_date,
#                 status=True,
#                 price=price,
#                 create_at=datetime.now().date(),
#                 updated_at=datetime.now().date(),
#             )
#
#             serializer = ReservationSerializer(reservation)
#             return Response(serializer.data, status=status.HTTP_201_CREATED)
#
#         except Exception as e:
#             return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# MODEL_PATH = ''
# device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
# model = AutoModelForSequenceClassification.from_pretrained(MODEL_PATH).to(device)
# tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH)


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
# class AISet(APIView):
#     def post(self, request):
#         """
#         숙소 추천 API
#         POST 요청으로 사용자의 위치와 조건을 받아 추천 숙소를 반환합니다.
#         """
#         try:
#             # 사용자 요청 데이터
#             user_location = request.data.get('user_location')  # [latitude, longitude]
#             max_distance = request.data.get('max_distance', 50)  # 최대 거리 (기본값 50km)
#
#             if not user_location:
#                 return Response({"error": "user_location is required"}, status=status.HTTP_400_BAD_REQUEST)
#
#             # 숙소 데이터 가져오기
#             accommodations = Accommodation.objects.all().values(
#                 "id", "name", "price", "latitude", "longitude", "ranks"
#             )
#             reviews = Review.objects.values("accommodation_id", "rating")
#
#             # 숙소와 리뷰를 DataFrame으로 변환
#             accommodation_df = pd.DataFrame(list(accommodations))
#             review_df = pd.DataFrame(list(reviews))
#
#             # 평균 리뷰 점수 추가
#             if not review_df.empty:
#                 review_avg = review_df.groupby("accommodation_id")["rating"].mean().reset_index()
#                 accommodation_df = accommodation_df.merge(review_avg, left_on="id", right_on="accommodation_id",
#                                                           how="left")
#                 accommodation_df.rename(columns={"rating": "avg_review_score"}, inplace=True)
#             else:
#                 accommodation_df["avg_review_score"] = 0.0
#
#             # 거리 계산
#             accommodation_df["distance"] = accommodation_df.apply(
#                 lambda row: geodesic(user_location, (row["latitude"], row["longitude"])).km, axis=1
#             )
#
#             # 거리 필터링
#             accommodation_df = accommodation_df[accommodation_df["distance"] <= max_distance]
#
#             if accommodation_df.empty:
#                 return Response({"message": "No accommodations found within the specified distance."},
#                                 status=status.HTTP_404_NOT_FOUND)
#
#             # 정규화 및 점수 계산
#             scaler = MinMaxScaler()
#             accommodation_df["distance_score"] = scaler.fit_transform(
#                 1 / (accommodation_df["distance"] + 1).values.reshape(-1, 1))
#             accommodation_df["price_score"] = scaler.fit_transform(
#                 1 / (accommodation_df["price"] + 1).values.reshape(-1, 1))
#
#             accommodation_df["final_score"] = (
#                     0.3 * accommodation_df["distance_score"] +
#                     0.3 * accommodation_df["ranks"] +
#                     0.2 * accommodation_df["avg_review_score"] +
#                     0.2 * accommodation_df["price_score"]
#             )
#
#             # 상위 10개 추천
#             recommended_hotels = accommodation_df.sort_values("final_score", ascending=False).head(10)
#             result = recommended_hotels[["name", "final_score", "distance", "ranks", "avg_review_score"]].to_dict(
#                 orient="records")
#
#             return Response({"recommended_hotels": result}, status=status.HTTP_200_OK)
#
#         except Exception as e:
#             return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)