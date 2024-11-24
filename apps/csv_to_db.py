import pandas as pd
from rest_framework.views import APIView
from django.db.models import Avg
from rest_framework.response import Response
from rest_framework import status
from .models import Accommodation, Review
from datetime import datetime
import os
from django.conf import settings
from django.db import transaction

csv_file_path = os.path.join(settings.BASE_DIR, 'hotels_with_coordinates.csv')

class LoadCSVToDBView(APIView):
    def get(self, request):
        try:
            for chunk in pd.read_csv(csv_file_path, encoding='utf-8', chunksize=1000):
                reviews = []
                ranks_map = {}
                existing_accommodations = {
                    acc.name: acc for acc in Accommodation.objects.all()
                }


                for row in chunk.itertuples(index=False):
                    price = 0 if pd.isna(row.price) or row.price == "가격 정보 없음" else int(str(row.price).replace(',', ''))

                    if row.hotel in existing_accommodations:
                        accommodation = existing_accommodations[row.hotel]                  
                    else:
                        accommodation = Accommodation.objects.create(
                                name=row.hotel,
                                address=row.address,
                                price=price,
                                latitude=row.latitude,
                                longitude=row.longitude,
                                ranks= 0.0,
                                )
                        existing_accommodations[row.hotel] = accommodation
                                                                                                            

                    reviews.append(Review(
                        accommodation=accommodation,
                        content=row.review,
                        rating=float(row.star),
                        created_at=datetime.now()
                        ))
                
                    if accommodation.id not in ranks_map:
                        ranks_map[accommodation.id] = []
                    ranks_map[accommodation.id].append(row.star)

                    if len(reviews) >= 100:
                        self._save_batch([], reviews)
                        reviews.clear()


                self._update_accommodation_ranks(ranks_map)

                return Response({"message": "CSV 데이터가 성공적으로 데이터베이스에 저장되었습니다."}, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def _save_batch(self, accommodations, reviews):
        with transaction.atomic():
            Accommodation.objects.bulk_create(accommodations, ignore_conflicts=True)
            Review.objects.bulk_create(reviews)

    def _update_accommodation_ranks(self, ranks_map):
        accommodations_to_update = []

        for acc_id, ratings in ranks_map.items():
            avg_rank = round(sum(ratings) / len(ratings), 2) if ratings else 0.0
            accommodations_to_update.append(Accommodation(id=acc_id, ranks=avg_rank))

        Accommodation.objects.bulk_update(accommodations_to_update, ['ranks'])



                
