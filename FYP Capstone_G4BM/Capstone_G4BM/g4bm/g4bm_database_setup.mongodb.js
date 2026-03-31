use('G4BM_Database');

// This command deletes ALL documents inside these collections, leaving them empty and ready!
db.getCollection('mood_entries').deleteMany({});
db.getCollection('sleep_entries').deleteMany({});

console.log("🧹 All fake data wiped! The database is clean and ready for real app data.");