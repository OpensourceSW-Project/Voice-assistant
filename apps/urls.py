"""
URL configuration for config project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path

from .models import Reservation
from .views import LikeAccommodation, AccommodationInfo, ReviewInfo, AISet, UserReservationInfo
from .csv_to_db import LoadCSVToDBView

urlpatterns = [
 #    path('load-csv/', LoadCSVToDBView.as_view(), name='load_csv_to_db'),
    path('like-accommodation/', LikeAccommodation.as_view(), name='like_accommodation'),
    path('accommodation-info/', AccommodationInfo.as_view(), name="user_reservation_info"),
    path('review-info/', ReviewInfo.as_view(), name="review_info"),
    path('ai-response/', AISet.as_view(), name='AI'),
    path('reservation-info/', UserReservationInfo.as_view(), name='reservation')
]
