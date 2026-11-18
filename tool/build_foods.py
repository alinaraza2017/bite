import json

def u(label, grams, cal, p, c, f, default=False):
    return {
        "label": label,
        "grams": grams,
        "is_default": default,
        "calories": cal,
        "protein": p,
        "carbs": c,
        "fat": f,
    }

def food(name, category, units, tadka=None):
    row = {
        "name": name,
        "category": category,
        "has_tadka": tadka is not None,
        "units": units,
    }
    if tadka:
        light, heavy = tadka
        row["tadka_light_kcal"] = light
        row["tadka_light_fat"] = round(light / 9, 4)
        row["tadka_heavy_kcal"] = heavy
        row["tadka_heavy_fat"] = round(heavy / 9, 4)
    return row

# Sample shifts from the spec.
karahi = (-45, 70)
gravy = (-40, 60)

foods = [
    food("Chicken Karahi", "Main meals", [u("1 karchi", 180, 320, 25, 8, 21, True), u("100 g", 100, 178, 14, 4, 12)], karahi),
    food("Mutton Karahi", "Main meals", [u("1 karchi", 180, 410, 28, 6, 30, True), u("100 g", 100, 228, 16, 3, 17)], karahi),
    food("Nihari", "Main meals", [u("1 plate", 350, 480, 32, 18, 30, True), u("1 karchi", 180, 250, 16, 9, 16)], gravy),
    food("Haleem", "Main meals", [u("1 plate", 300, 390, 22, 40, 14, True), u("1 karchi", 180, 230, 13, 24, 8)], gravy),
    food("Chicken Curry", "Main meals", [u("1 karchi", 180, 280, 24, 8, 16, True), u("1 pyali", 250, 360, 30, 10, 20)], gravy),
    food("Korma", "Main meals", [u("1 karchi", 180, 340, 22, 10, 24, True), u("1 pyali", 250, 450, 28, 14, 32)], gravy),
    food("Aloo Gosht", "Main meals", [u("1 pyali", 250, 310, 18, 20, 16, True)], gravy),
    food("Keema", "Main meals", [u("1 karchi", 160, 290, 22, 8, 20, True)], gravy),
    food("Paya", "Main meals", [u("1 paya", 250, 220, 24, 2, 12, True)], gravy),
    food("Palak Gosht", "Main meals", [u("1 pyali", 250, 280, 20, 8, 18, True)], gravy),
    food("Kofta Curry", "Main meals", [u("1 pyali", 250, 330, 18, 12, 22, True)], gravy),
    food("Chicken Handi", "Main meals", [u("1 karchi", 180, 300, 26, 6, 18, True)], gravy),
    food("Chicken Tikka", "Main meals", [u("1 piece", 80, 150, 18, 2, 8, True), u("1 plate", 200, 360, 42, 6, 18)], None),
    food("Malai Boti", "Main meals", [u("1 plate", 200, 420, 32, 8, 28, True)], None),
    food("Biryani", "Rice", [u("1 plate", 350, 520, 24, 68, 16, True), u("1 pyali", 200, 300, 14, 40, 9)], gravy),
    food("Beef Biryani", "Rice", [u("1 plate", 350, 560, 28, 64, 20, True)], gravy),
    food("Chicken Biryani", "Rice", [u("1 plate", 350, 500, 26, 62, 14, True)], gravy),
    food("Pulao", "Rice", [u("1 pyali", 200, 280, 8, 46, 8, True)], gravy),
    food("Daal Chawal", "Rice", [u("1 plate", 350, 430, 16, 62, 12, True)], gravy),
    food("Khichri", "Rice", [u("1 pyali", 250, 240, 10, 40, 4, True)], gravy),
    food("Plain Rice", "Rice", [u("1 pyali", 200, 220, 4, 48, 1, True), u("100 g", 100, 130, 2, 28, 0)], None),
    food("Zeera Rice", "Rice", [u("1 pyali", 200, 240, 4, 46, 4, True)], None),
    food("Roti", "Roti", [u("1 roti", 40, 120, 3, 22, 2, True)], None),
    food("Chapati", "Roti", [u("1 chapati", 30, 80, 3, 15, 1, True)], None),
    food("Naan", "Roti", [u("1 naan", 100, 290, 8, 50, 6, True)], None),
    food("Tandoori Roti", "Roti", [u("1 roti", 90, 260, 8, 48, 4, True)], None),
    food("Taftan", "Roti", [u("1 piece", 80, 240, 6, 40, 6, True)], None),
    food("Puri", "Roti", [u("1 puri", 30, 120, 2, 14, 6, True)], None),
    food("Paratha", "Breakfast", [u("1 paratha", 80, 260, 5, 32, 12, True)], gravy),
    food("Aloo Paratha", "Breakfast", [u("1 paratha", 120, 320, 7, 42, 14, True)], gravy),
    food("Halwa Puri", "Breakfast", [u("1 plate", 250, 540, 10, 70, 24, True)], None),
    food("Anda (boiled)", "Breakfast", [u("1 egg", 50, 95, 6, 1, 7, True)], None),
    food("Anda (fried)", "Breakfast", [u("1 egg", 60, 120, 6, 1, 10, True)], None),
    food("Omelette", "Breakfast", [u("1 omelette", 120, 180, 12, 2, 14, True)], gravy),
    food("Halwa", "Breakfast", [u("1 pyali", 150, 280, 3, 40, 12, True)], gravy),
    food("Daal", "Daal & Veg", [u("1 pyali", 200, 190, 12, 28, 4, True), u("1 karchi", 120, 110, 7, 16, 2)], gravy),
    food("Daal Chana", "Daal & Veg", [u("1 pyali", 200, 210, 13, 30, 4, True)], gravy),
    food("Daal Masoor", "Daal & Veg", [u("1 pyali", 200, 180, 12, 26, 3, True)], gravy),
    food("Daal Mash", "Daal & Veg", [u("1 pyali", 200, 200, 13, 28, 4, True)], gravy),
    food("Chana", "Daal & Veg", [u("1 pyali", 200, 230, 12, 32, 6, True)], gravy),
    food("Aloo Sabzi", "Daal & Veg", [u("1 pyali", 200, 160, 3, 22, 6, True)], gravy),
    food("Karela Sabzi", "Daal & Veg", [u("1 pyali", 180, 140, 3, 14, 8, True)], gravy),
    food("Mix Sabzi", "Daal & Veg", [u("1 pyali", 200, 150, 3, 16, 8, True)], gravy),
    food("Bhindi", "Daal & Veg", [u("1 pyali", 180, 130, 3, 12, 7, True)], gravy),
    food("Aloo Palak", "Daal & Veg", [u("1 pyali", 200, 150, 4, 16, 7, True)], gravy),
    food("Sabzi", "Daal & Veg", [u("1 pyali", 200, 140, 3, 14, 7, True)], gravy),
    food("Samosa", "Snacks", [u("1 piece", 60, 260, 5, 28, 14, True)], None),
    food("Pakora", "Snacks", [u("1 piece", 30, 80, 2, 8, 4, True), u("1 plate", 150, 380, 8, 36, 22)], None),
    food("Chapli Kebab", "Snacks", [u("1 piece", 120, 280, 18, 8, 20, True)], None),
    food("Seekh Kebab", "Snacks", [u("1 seekh", 80, 180, 14, 4, 12, True)], None),
    food("Shami Kebab", "Snacks", [u("1 piece", 50, 140, 8, 8, 8, True)], None),
    food("Bun Kebab", "Snacks", [u("1 bun", 180, 420, 16, 48, 18, True)], None),
    food("Dahi Bhalla", "Snacks", [u("1 plate", 200, 240, 8, 32, 8, True)], None),
    food("Gol Gappay", "Snacks", [u("1 plate", 150, 180, 4, 32, 4, True)], None),
    food("Chana Chaat", "Snacks", [u("1 plate", 200, 260, 10, 40, 6, True)], gravy),
    food("Fruit Chaat", "Snacks", [u("1 plate", 200, 140, 2, 32, 1, True)], None),
    food("Chicken Roll", "Snacks", [u("1 roll", 180, 380, 18, 40, 16, True)], None),
    food("Sweet lassi", "Drinks", [u("1 glass", 250, 180, 6, 28, 5, True)], None),
    food("Salty lassi", "Drinks", [u("1 glass", 250, 120, 6, 10, 5, True)], None),
    food("Chai", "Drinks", [u("1 cup", 150, 70, 2, 10, 2, True)], None),
    food("Doodh", "Drinks", [u("1 glass", 250, 150, 8, 12, 8, True)], None),
    food("Dahi", "Drinks", [u("1 pyali", 150, 90, 5, 6, 5, True)], None),
    food("Kashmiri Chai", "Drinks", [u("1 cup", 150, 110, 2, 14, 5, True)], None),
    food("Raita", "Drinks", [u("1 pyali", 120, 60, 3, 6, 2, True)], None),
    food("Nimbu Pani", "Drinks", [u("1 glass", 250, 50, 0, 12, 0, True)], None),
    food("Rooh Afza", "Drinks", [u("1 glass", 250, 120, 0, 30, 0, True)], None),
    food("Kheer", "Desserts", [u("1 pyali", 150, 260, 7, 42, 8, True)], None),
    food("Firni", "Desserts", [u("1 pyali", 150, 220, 5, 38, 6, True)], None),
    food("Jalebi", "Desserts", [u("1 piece", 30, 150, 1, 28, 4, True)], None),
    food("Gulab Jamun", "Desserts", [u("1 piece", 40, 140, 2, 20, 6, True)], None),
    food("Zarda", "Desserts", [u("1 pyali", 180, 280, 4, 52, 6, True)], None),
    food("Fruit Custard", "Desserts", [u("1 pyali", 180, 200, 5, 30, 6, True)], None),
]

assert 60 <= len(foods) <= 80, len(foods)
names = {row["name"] for row in foods}
needed = [
    "Paratha", "Anda (boiled)", "Anda (fried)", "Halwa Puri", "Chicken Karahi",
    "Mutton Karahi", "Nihari", "Haleem", "Chicken Curry", "Korma", "Biryani",
    "Plain Rice", "Roti", "Chapati", "Naan", "Daal", "Chana", "Aloo Sabzi",
    "Karela Sabzi", "Mix Sabzi", "Samosa", "Pakora", "Sweet lassi", "Salty lassi",
    "Chai", "Kheer",
]
missing = [name for name in needed if name not in names]
assert not missing, missing
path = r"D:\NON TECH\7TH SSEM\SC\Bite\assets\data\foods.json"
with open(path, "w", encoding="utf-8", newline="\n") as handle:
    json.dump({"version": 2, "foods": foods}, handle, indent=2)
    handle.write("\n")
print(len(foods))
