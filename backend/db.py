# db.py - Mock database for development

class MockCollection:
    def __init__(self, name):
        self.name = name
        self.data = {}
    
    def find_one(self, query):
        return self.data.get(query.get("_id"))
    
    def insert_one(self, doc):
        self.data[doc.get("_id")] = doc
        return {"inserted_id": doc.get("_id")}
    
    def update_one(self, query, update):
        return {"modified_count": 1}

users_col = MockCollection("users")
tasks_col = MockCollection("tasks")
transactions_col = MockCollection("transactions")