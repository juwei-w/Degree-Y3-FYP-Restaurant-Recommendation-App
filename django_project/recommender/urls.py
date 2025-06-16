# recommender/urls.py

from django.urls import path
from . import get_restaurants

urlpatterns = [
    path('get_restaurants/', get_restaurants.get_restaurants_api, name='api_get_restaurants'),
]