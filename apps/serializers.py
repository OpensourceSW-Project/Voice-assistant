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

class AccommodationSerializer(serializers.ModelSerializer):
    avg_review_score = serializers.FloatField(default=0.0)
    distance = serializers.FloatField()
    final_score = serializers.FloatField()

    class Meta:
        model = Accommodation
        fields = ['id', 'name', 'price', 'latitude', 'longitude', 'ranks', 'avg_review_score', 'distance',
                  'final_score']
