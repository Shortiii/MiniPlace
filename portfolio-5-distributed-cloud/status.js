// Shows who is PRIMARY and who is SECONDARY.
// Usage (pick any node that is running):
//   mongosh --port 27117 --quiet --file status.js
//   mongosh --port 27118 --quiet --file status.js
const s = rs.status();
print("Replica set: " + s.set);
s.members.forEach(function (m) {
  print(m.name + "  ->  " + m.stateStr + (m.health === 0 ? "  (DOWN)" : ""));
});
