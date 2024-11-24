import pandas as pd
from rest_framework.views import APIView
from django.db.models import Avg
from rest_framework.response import Response
from rest_framework import status
from modles import Accommodation, Review
from datetime import datetime
import os
from django.conf import settings
from django.db import transaction

csv_file_path = os.path.join(settings.BASE_DIR, 'hotels_with_coordinates.csv')

class LoadCSVToDBView(APIView):
    def get(self, request):
        try:
            df = pd.read_csv(csv_file_path, encoding='utf-8')

            accommodations = []
            reviews = []      

            for index, row in df.iterrows():
                price = row['price']
                if pd.isna(price) or price == "가격 정보 없음":
                    price = 0
                elif isinstance(price, str):
                    price = int(price.replace(',', ''))
                else:
                    price = int(price)

                 accommodation, created = Accommodation.objects.get_or_create(
                                             name=row['hotel'],
                                             defaults={
                                             'address': row['address'],
                                             'price': price,
                                             'ranks': 0.0,
                                             }
                                        )

                 reviews.append(Review(
                     accommodation=accommodation,
                     content=row['review'],
                     rating=float(row['star']),
                     created_at=datetime.now()
                     ))

                 avg_rank = Review.objects.filter(accommodation=accommodation).aggregate(Avg('rating'))['rating__avg']
                 accommodation.ranks = round(avg_rank, 2) if avg_rank else 0.0
                 accommodations.append(accommodation)

                 if len(reviews) >= 100:
                     with transaction.atomic():
                         Accommodation.objects.bulk_update(accommodations, ['ranks'])
                         Review.objects.bulk_create(reviews)
                    reviews.clear()
                    accommodations.clear()

            if reviews:
                with transaction.atomic():
                    Accommodation.objects.bulk_update(accommodations, ['ranks'])
                    Review.objects.bulk_create(reviews)

            return Response({"message": "CSV 데이터가 성공적으로 데이터베이스에 저장되었습니다."}, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)




                
