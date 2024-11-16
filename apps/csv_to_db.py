import pandas as pd
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Accommodation


class LoadCSVToDBView(APIView):

    def get(self, request):
        if Accommodation.objects.exists():
            return Response({"message": "데이터가 이미 존재합니다. 중복 실행 방지."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            df = pd.read_csv('combined_public_data.csv', encoding='utf-8')

            for index, row in df.iterrows():
                Accommodation.objects.create(
                    name=row['업체명'],
                    address=row['주소'],
                    number=row['전화번호'],
                    no_of_rooms=row['객실수'],
                    urls=row['홈페이지']
                )

            return Response({"message": "CSV 데이터가 성공적으로 데이터베이스에 저장되었습니다."}, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
