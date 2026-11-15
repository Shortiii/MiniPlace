// Initiates a 3-member replica set named rs0 (run once, via setup-replica-set.ps1)
printjson(rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "localhost:27117" },
    { _id: 1, host: "localhost:27118" },
    { _id: 2, host: "localhost:27119" }
  ]
}));
