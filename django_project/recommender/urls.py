# recommender/urls.py

from django.urls import path
# from . import get_restaurants
from . import views

urlpatterns = [
    # path('get_restaurants/', get_restaurants.get_restaurants_api, name='api_get_restaurants'),
    path('get_restaurants/', views.get_restaurants_api, name='get_restaurants_api'),
]