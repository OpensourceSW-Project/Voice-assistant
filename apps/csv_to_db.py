import pandas as pd
from rest_framework.views import APIView
from django.db.models import Avg
from rest_framework.response import Response
from rest_framework import status
from .models import Accommodation, Review
from datetime import datetime


# class LoadCSVToDBView(APIView):
#
#     def get(self, request):
#
#         try:
#             df = pd.read_csv('hotels_with_coordinates.csv', encoding='utf-8')
#
#             for index, row in df.iterrows():
#                 price = row['price']
#                 if pd.isna(price) or price == "가격 정보 없음":
#                     price = 0
#                 elif isinstance(price, str):
#                     price = int(price.replace(',', ''))
#                 else:
#                     price = int(price)
#
#                 accommodation, _ = Accommodation.objects.get_or_create(
#                     name=row['hotel'],
#                     defaults={
#                         'address': row['address'],
#                         'price': price,
#                         'ranks': 0.0,
#                     }
#                 )
#
#                 Review.objects.create(
#                     accommodation=accommodation,
#                     content=row['review'],
#                     rating=float(row['star']),
#                     created_at=datetime.now()
#                 )
#
#                 avg_rank = Review.objects.filter(accommodation=accommodation).aggregate(Avg('rating'))['rating__avg']
#                 accommodation.ranks = round(avg_rank, 2) if avg_rank else 0.0
#                 accommodation.save()
#
#             return Response({"message": "CSV 데이터가 성공적으로 데이터베이스에 저장되었습니다."}, status=status.HTTP_200_OK)
#
#         except Exception as e:
#             return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
