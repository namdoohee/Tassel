# db.py - Mock database for development

class MockCollection:
    def __init__(self, name):
        self.name = name
        self.data = {}
    
    def find_one(self, query):
        # Mock find
        return self.data.get(query.get("_id"))
    
    def insert_one(self, doc):
        # Mock insert
        self.data[doc.get("_id")] = doc
        return {"inserted_id": doc.get("_id")}
    
    def update_one(self, query, update):
        # Mock update
        return {"modified_count": 1}

# Export mock collections
users_col = MockCollection("users")
tasks_col = MockCollection("tasks")
transactions_col = MockCollection("transactions")
# Now your `app.py` will run without MongoDB! ✅