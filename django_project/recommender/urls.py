# recommender/urls.py

from django.urls import path
from . import views

urlpatterns = [
    path('get_restaurants/', views.get_restaurants_api, name='api_get_restaurants'),
]