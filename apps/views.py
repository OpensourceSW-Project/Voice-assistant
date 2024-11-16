from django.core.serializers import serialize
from rest_framework.views import APIView
from rest_framework import status
from rest_framework.response import Response

from apps.serializers import ReservationSerializer, AccommodationSerializer
from apps.models import Reservation, Accommodation, User


# 숙소 정보 조회 GET(완)

# 좋아요 기능 GET, POST, DELETE(완)

# 추후
# 사용자 예약 정보 조회, 생성
# POST Request
# user_id, check_in_date, check_out_date, status, price, create_at, updated_at, ranks
# GET Response
# reservation, user_id, check_in_date, check_out_date, status, price, create_at, updated_at, ranks

# AI 연결은 AI 완성 후 결정


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
#         pass

class AccommodationInfo(APIView):
    # 숙소 정보 조회
    def get(self, request, format=None):
        # 예시 : api/accommodation-info/?accomodation_name=OO호텔
        accommodation_name = request.query_params.get('accommodation_name')

        # 파라미터에 숙소 이름을 넣으면 그 숙소만 검색
        if accommodation_name:
            accommodation = Accommodation.objects.filter(name__icontains=accommodation_name)
            if accommodation.exists():
                serializer = AccommodationSerializer(accommodation, many=True)
                return Response(serializer.data, status=status.HTTP_200_OK)
            else:
                return Response({"error": "not found accommodation name"})

        # 예시 : api/accommodation-info/
        # 아니면 모든 숙소 정보 검색
        else:
            accommodation = Accommodation.objects.all()
            serializer = AccommodationSerializer(accommodation, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)


class LikeAccommodation(APIView):
    # 해당 유저의 좋아요 조회
    def get(self, request, format=None):
        user_id = request.query_params.get('user_id')

        if not user_id:  # user_id를 query_params에 안넣었을 때
            return Response({"error": "user_id required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response({"error" : "User not found"}, status=status.HTTP_404_NOT_FOUND)

        liked_list = user.likes.all()
        serializer = AccommodationSerializer(liked_list, many=True)

        return Response(serializer.data, status=status.HTTP_200_OK)

    # 유저 좋아요 생성
    def post(self, request, format=None):
        user_id = request.query_params.get('user_id')
        accommodation_name = request.query_params.get('accommodation_name')

        if not user_id or not accommodation_name: # user_id과 accommodation_name을 query_params에 안넣었을 때
            return Response({"error": "user_id accommodation_name required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.get(id=user_id)
            accommodation = Accommodation.objects.get(name=accommodation_name)
        except User.DoesNotExist:
            return Response({"error" : "User not found"}, status=status.HTTP_404_NOT_FOUND)
        except Accommodation.DoesNotExist:
            return Response({"error": "Accommodation not found"}, status=status.HTTP_404_NOT_FOUND)

        accommodation.like.add(user)
        return Response({"message" : "like complete"}, status=status.HTTP_200_OK)

    # 유저 좋아요 삭제
    def delete(self, request, format=None):
        user_id = request.query_params.get('user_id')
        accommodation_name = request.query_params.get('accommodation_name')

        if not user_id or not accommodation_name: # user_id과 accommodation_name을 query_params에 안넣었을 때
            return Response({"error": "user_id accommodation_name required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.get(id=user_id)
            accommodation = Accommodation.objects.get(name=accommodation_name)
        except User.DoesNotExist:
            return Response({"error" : "User not found"}, status=status.HTTP_404_NOT_FOUND)
        except Accommodation.DoesNotExist:
            return Response({"error": "Accommodation not found"}, status=status.HTTP_404_NOT_FOUND)

        if accommodation.like.filter(id=user.id).exists():
            accommodation.like.remove(user) # 좋아요 삭제
            return Response({"message": "remove complete"}, status=status.HTTP_200_OK)
        else:
            return Response({"message" : "like not found this user"}, status=status.HTTP_404_NOT_FOUND)

class AISet():
    pass