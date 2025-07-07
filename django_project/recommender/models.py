from django.db import models
import uuid

class UserFeedback(models.Model):
    """
    Stores feedback events from users to train the RL model.
    """
    ACTION_CHOICES = [
        ('like', 'Like'),
        ('dislike', 'Dislike'),
        ('click_details', 'Click Details'), # When user views the restaurant
        ('skip', 'Skip'), # When user swipes away
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user_id = models.CharField(max_length=255, db_index=True)
    restaurant_id = models.CharField(max_length=255, db_index=True)
    action = models.CharField(max_length=15, choices=ACTION_CHOICES)
    score_at_recommendation = models.FloatField(default=0.0) # The hybrid score when it was shown
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user_id} -> {self.action} -> {self.restaurant_id}"
