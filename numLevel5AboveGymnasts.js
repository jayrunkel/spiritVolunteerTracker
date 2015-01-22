db.signUps.aggregate([
{$unwind : "$gymnasts"},
{$match : {"gymnasts.level" : {"$in" : ["XG", "5", "6", "7", "8", "9", "10"]}}},
{$group : {"_id" : null, count : {$sum : 1}}}])