from rest_framework import serializers

from apps.models import Reservation, Accommodation, Review


class ReservationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Reservation
        fields = '__all__'

class ReviewSerializer(serializers.ModelSerializer):
    class Meta:
        model = Review
        fields = '__all__'

class AccommodationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Accommodation
        fields = ['id', 'name', 'price', 'ranks', 'address']

class LikeAccommodationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Accommodation
        fields = '__all__'

class HotelRouteResponseSerializer(serializers.ModelSerializer):
    latitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    longitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    transit_time = serializers.CharField(help_text="대중교통 소요 시간")
    car_time = serializers.CharField(help_text="자동차 소요 시간")

    class Meta:
        model = Accommodation
        fields = ['name', 'address', 'latitude', 'longitude', 'transit_time', 'car_time']