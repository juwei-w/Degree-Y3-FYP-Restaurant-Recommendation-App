"""
This file contains shared constants and configurations used across the recommender system
to ensure consistency and a single source of truth.
"""

# The master dictionary for mapping keywords to standardized category names.
# This is the single source of truth for all category definitions.
CATEGORY_DICT = {
    "halal": ["halal", "muslim-friendly", "muslim", "halal-certified", "shariah-compliant"],
    "vegetarian": ["vege", "vegetarian", "vegetarian-friendly", "meat-free"],
    "vegan": ["vegan", "plant-based", "vegan-friendly", "cruelty-free", "dairy-free"],
    "pork-free": ['pork-free', 'no pork'],
    "beef-free": ["beef-free", "no beef", "without beef", "beefless"],
    "chinese": ["chinese", "szechuan", "dim sum", "cantonese", "dumplings", "fried rice", "chicken rice", "charsiew", "horfun", "kopitiam", "mala"],
    "malay": ["nasi lemak", "satay", "rendang", "keropok", "nasi kerabu", "roti jala"],
    "indian": ["indian restaurant", "khorma", "masala", "naan", "briyani", "tandoori", "nasi kandar"],
    "korean": ["korean", "kimchi", "bibimbap", "bulgogi", "tteokbokki", "jajangmyeon", "samgyeopsal"],
    "japanese": ["japan", "japanese", "sushi", "wasabi", "udon", "miso", "shabu-shabu", "bento", "sukiya", "takoyaki", "onigiri"],
    "thai": ["thai", "pad thai", "green curry", "tom yum", "som tam", "satay", "red curry"],
    "western": ["western", "steak", "burger", "pasta", "pizza", "fish n' chips"],
    "middle-eastern": ["eastern cuisine", "middle eastern", "falafel", "shawarma", "hummus", "kebab"],
    "vietnamese": ["vietnamese", "pho", "banh mi"],
    "mexican": ["mexican", "taco", "burrito", "nachos"],
    "italian": ["italian", "pasta", "pizza", "risotto"],
    "indonesian": ["indonesian", "nasi goreng", "sate"],
    "cafe": ["café", "coffee shop", "espresso", "latte", "pastry", "barista"],
    "bar": ["bar", "pub", "tavern", "brewery", "cocktail"],
    "fast-food": ["fast food", "drive-thru", "mcdonald's", "kfc", "burger king", "a&w", "taco bell", "subway", "pizza hut", "domino's", "texas chicken"],
    "seafood": ['seafood', 'fish', 'prawn', 'crab', 'oyster'],
    "dessert": ['dessert', 'ice cream', 'cake', 'bingsu'],
    "bakery": ['bakery', 'bread', 'pastries', 'croissant'],
    "steamboat": ['steamboat', 'hot pot', 'shabu-shabu'],
    "bbq": ['bbq', 'barbecue', 'grill', 'yakiniku'],
    "noodle": ['noodle', 'ramen', 'laksa', 'pan mee'],
    "rice": ['rice', 'nasi', 'porridge'],
    "soup": ['soup', 'broth'],
    "breakfast": ['breakfast'],
    "brunch": ['brunch'],
    "lunch": ['lunch'],
    "dinner": ['dinner'],
    "buffet": ["buffet", "all-you-can-eat", "unlimited food", "buffet-style"],
}

# The master list of standardized category keys, derived from the dictionary.
# This is used for creating one-hot encoded vectors in the recommendation models.
CATEGORY_KEYS = sorted(list(CATEGORY_DICT.keys()))

# Types of places to exclude from Google Maps results.
EXCLUDED_TYPES = ['gas_station', 'lodging', 'convenience_store', 'car_repair', 'car_wash', 'parking']