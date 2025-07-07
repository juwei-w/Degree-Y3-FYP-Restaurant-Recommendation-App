from django.urls import path
from . import views

urlpatterns = [
    path('get_restaurants/', views.get_restaurants_api, name='get_restaurants_api'),
    path('hybrid_recommendations/', views.get_hybrid_recommendations_api, name='get_hybrid_recommendations_api'),
    path('record_feedback/', views.record_feedback, name='record_feedback'),
]