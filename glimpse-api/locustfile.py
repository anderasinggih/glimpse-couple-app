import os
import random
import queue
from locust import HttpUser, task, between

# Get number of pre-seeded users from environment (defaults to 1000)
NUM_USERS = int(os.environ.get("LOCUST_NUM_USERS", "1000"))

# Thread-safe credentials queue
credentials_queue = queue.Queue()
for i in range(1, (NUM_USERS // 2) + 1):
    credentials_queue.put(("test_user_{}_a@glimpse.test".format(i), "password"))
    credentials_queue.put(("test_user_{}_b@glimpse.test".format(i), "password"))

class GlimpseLoadTestUser(HttpUser):
    # Simulated users wait 1 to 3 seconds between tasks to mimic real human behavior
    wait_time = between(1, 3)

    def on_start(self):
        """Called when a virtual user is spawned."""
        # Get unique credentials from the queue
        try:
            self.email, self.password = credentials_queue.get_nowait()
        except queue.Empty:
            # Fallback if we spawn more virtual users than pre-seeded accounts
            rand_idx = random.randint(1, NUM_USERS // 2)
            rand_suffix = random.choice(["a", "b"])
            self.email = "test_user_{}_{}@glimpse.test".format(rand_idx, rand_suffix)
            self.password = "password"

        # Log in to get Sanctum access token
        self.headers = {"Accept": "application/json"}
        response = self.client.post("/api/login", json={
            "email": self.email,
            "password": self.password
        })

        if response.status_code == 200:
            data = response.json()
            self.token = data.get("access_token")
            self.headers["Authorization"] = "Bearer {}".format(self.token)
        else:
            self.token = None
            print("Failed login for user: {}".format(self.email))

    @task(5)
    def get_state(self):
        """Simulate app opening / foreground sync."""
        if self.token:
            self.client.get("/api/glimpse/state", headers=self.headers)

    @task(4)
    def update_status(self):
        """Simulate real-time location and status updates."""
        if self.token:
            # Random coordinates around Jakarta
            lat = -6.2088 + (random.randint(-100, 100) / 10000.0)
            lng = 106.8456 + (random.randint(-100, 100) / 10000.0)
            self.client.post("/api/glimpse/status", headers=self.headers, json={
                "latitude": lat,
                "longitude": lng,
                "battery_level": random.randint(10, 100),
                "is_charging": random.choice([True, False]),
                "status_note": random.choice(["Busy coding", "On the way", "Chilling", "Battery low", "Miss you ❤️"]),
                "location_name": random.choice(["Home", "Office", "Cafe", "Gym", None])
            })

    @task(3)
    def get_messages(self):
        """Simulate checking chat history."""
        if self.token:
            self.client.get("/api/glimpse/chat", headers=self.headers)

    @task(1)
    def send_message(self):
        """Simulate sending a text message."""
        if self.token:
            self.client.post("/api/glimpse/chat", headers=self.headers, json={
                "message": random.choice([
                    "Hello!", "Where are you?", "Just saw your status", "Call me when you can", "❤️", "Busy right now"
                ])
            })
