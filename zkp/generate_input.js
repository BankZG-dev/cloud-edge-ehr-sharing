const fs = require("fs");

// Example input values
const userID = 123;
const domainCode = 2;     // Domain weight = 2 * 2 = 4
const roleCode = 1;       // Role weight = 3 * 1 = 3
const random = 987654321;
const threshold = 7;      // 4 + 3 = 7 → should pass

const inputJson = {
  userID,
  domainCode,
  roleCode,
  random,
  threshold
};

fs.writeFileSync("input.json", JSON.stringify(inputJson, null, 2));
console.log("✅ input.json generated!");
