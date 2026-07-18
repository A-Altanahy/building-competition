var teamPoints = [0, 0, 0, 0, 0];
var previousRoundPoints = [];
var previousBuildings = {};
const buildingValues = {
  "بيت": 200,
  "بقالة": 350,
  "سوق": 400,
  "فندق": 450,
  "مصنع": 600,
  "مجمع": 600
};
const buildingPrices = {
  "بيت": 100,
  "بقالة": 200,
  "سوق": 300,
  "فندق": 400,
  "مصنع": 1000,
  "مجمع": 1000
};

$(document).ready(function () {
  initializeTable();

  $("#endRoundButton").click(endRound);
  $("#undoLastRoundButton").click(undoPreviousRound);
  $("#sendButton").click(addPoints);
  $("#deleteButton").click(removePoints);

  // Event delegation for updating display table and adjusting surrounding values
  $("#table1, #displayTable").on('change', 'select', function(event) {
    const target = $(event.target);
    if (target.attr('id').startsWith('building')) {
      const index = target.attr('id').replace('building', '');
      adjustBuildingValuesInstant();
    }
    updateDisplayTable();
  });
});

function initializeTable() {
  var tbody = $("#table1 tbody");

  tbody.append(createRow(1, 10, 1));
  for (var i = 1; i <= 8; i++) {
    tbody.append(createRow(i * 10 + 1, i * 10 + 10, i * 10 + 1));
  }
  tbody.append(createRow(91, 100, 91));

  updateDisplayTable();
}

function createRow(start, end, indexBase) {
  var row = "<tr>";
  for (var j = start; j <= end; j++) {
    row += "<td>" + createCell(indexBase + j - start) + "</td>";
  }
  row += "</tr>";
  return row;
}

function createCell(index) {
  return `
    <button type='button' class='btn btn-info'>${index}</button>
    <select id='team${index}'>
      <option value='0'>None</option>
      <option value='team1'>علي بن أبي طالب</option>
      <option value='team2'>مصعب بن عمير</option>
      <option value='team3'>عبدالله بن عمر</option>
      <option value='team4'>عبدالله بن عباس</option>
      <option value='team5'>أنس بن مالك</option>
    </select>
    <select id='building${index}'>
      <option value='بيت'>بيت</option>
      <option value='بقالة'>بقالة</option>
      <option value='سوق'>سوق</option>
      <option value='فندق'>فندق</option>
      <option value='مصنع'>مصنع</option>
      <option value='مجمع'>مجمع</option>
    </select>
    <select id='buildingValue${index}'>
      <option value=50>50</option>
      <option value=200>200</option>
      <option value=250>250</option>
      <option value=300>300</option>
      <option value=350>350</option>
      <option value=400>400</option>
      <option value=450>450</option>
      <option value=500>500</option>
      <option value=550>550</option>
      <option value=600>600</option>
    </select>
  `;
}

function endRound() {
  previousRoundPoints = [...teamPoints];
  var newBuildings = {};
  for (var i = 1; i <= 100; i++) {
    var teamIndex = parseInt($("#team" + i).val().replace('team', '')) - 1;
    var building = $("#building" + i).val();
    var value = Number($("#buildingValue" + i).val());

    if (teamIndex >= 0) {
      teamPoints[teamIndex] += value;
      // Check if a new building was added
      if (!previousBuildings[i] || previousBuildings[i].building !== building) {
        teamPoints[teamIndex] -= buildingPrices[building];
      }
      newBuildings[i] = { team: teamIndex, building: building };
    }
  }
  previousBuildings = newBuildings; // Update previous buildings state
  displayResults();
}

function undoPreviousRound() {
  if (previousRoundPoints.length) {
    teamPoints = [...previousRoundPoints];
    displayResults();
    previousRoundPoints = [];
  } else {
    alert("No previous round to undo");
  }
}

function adjustBuildingValuesInstant() {
  resetBuildingValues();
  var allIndices = [];
  for (var i = 1; i <= 100; i++) {
    allIndices.push(i);
  }

  for (var idx of allIndices) {
    var building = $("#building" + idx).val();
    if (building === "مجمع" || building === "مصنع") {
      var affectedIndices = getSurroundingIndices(idx);
      for (var affectedIndex of affectedIndices) {
        var surroundingBuildings = getSurroundingBuildings(affectedIndex);
        if (surroundingBuildings.includes("مجمع") && surroundingBuildings.includes("مصنع")) {
          // If both مجمع and مصنع are around, keep the original value
          var buildingType = $("#building" + affectedIndex).val();
          $(`#buildingValue${affectedIndex}`).val(buildingValues[buildingType]);
        } else if (surroundingBuildings.includes("مجمع")) {
          applyمجمعEffect(affectedIndex);
        } else if (surroundingBuildings.includes("مصنع")) {
          applyمصنعEffect(affectedIndex);
        }
      }
    }
  }
}

function resetBuildingValues() {
  for (var i = 1; i <= 100; i++) {
    var buildingType = $("#building" + i).val();
    $(`#buildingValue${i}`).val(buildingValues[buildingType]);
  }
}

function getSurroundingIndices(index) {
  var surroundingIndices = [];
  var row = Math.ceil(index / 10);
  var col = index % 10 === 0 ? 10 : index % 10;
  var directions = [
    { r: -1, c: -1 }, { r: -1, c: 0 }, { r: -1, c: 1 },
    { r: 0, c: -1 }, { r: 0, c: 1 },
    { r: 1, c: -1 }, { r: 1, c: 0 }, { r: 1, c: 1 }
  ];

  for (var dir of directions) {
    var newRow = row + dir.r;
    var newCol = col + dir.c;
    if (newRow >= 1 && newRow <= 10 && newCol >= 1 && newCol <= 10) {
      var newIndex = (newRow - 1) * 10 + newCol;
      surroundingIndices.push(newIndex);
    }
  }

  return surroundingIndices;
}

function getSurroundingBuildings(index) {
  var surroundingBuildings = [];
  var surroundingIndices = getSurroundingIndices(index);
  for (var i of surroundingIndices) {
    var building = $("#building" + i).val();
    surroundingBuildings.push(building);
  }
  return surroundingBuildings;
}

function applyمجمعEffect(index) {
  var building = $("#building" + index).val();
  switch (building) {
    case "بيت":
      $(`#buildingValue${index}`).val(350);
      break;
    case "فندق":
      $(`#buildingValue${index}`).val(600);
      break;
    case "بقالة":
      $(`#buildingValue${index}`).val(200);
      break;
    case "سوق":
      $(`#buildingValue${index}`).val(250);
      break;
  }
}

function applyمصنعEffect(index) {
  var building = $("#building" + index).val();
  switch (building) {
    case "بيت":
      $(`#buildingValue${index}`).val(50);
      break;
    case "فندق":
      $(`#buildingValue${index}`).val(300);
      break;
    case "بقالة":
      $(`#buildingValue${index}`).val(500);
      break;
    case "سوق":
      $(`#buildingValue${index}`).val(550);
      break;
  }
}

function updateDisplayTable() {
  $("#displayTable").html("");
  var row = "<tr>";
  for (var i = 1; i <= 100; i++) {
    var team = $("#team" + i).val();
    var building = $("#building" + i).val();
    var value = Number($("#buildingValue" + i).val());
    row += "<td>" + generateButton(team, building, value, i) + "</td>";
    if (i % 10 === 0) {
      row += "</tr><tr>";
    }
  }
  row += "</tr>";
  $("#displayTable").append(row);
}

function generateButton(team, building, value, i) {
  var teamName = getTeamName(team);
  var buildingInfo = getBuildingInfo(building);
  var buttonClass = getButtonClass(team);

  if (team === "0") {
    return `<button type='button' class='btn btn-secondary'><i class='fas fa-question-circle'></i><br>${i}<br>------------------</button>`;
  } else {
    return `<button type='button' class='btn ${buttonClass}'><br>${i}<br>${teamName}<br>${buildingInfo.name} ${value}</button>`;
  }
}

function getTeamName(team) {
  var teamNames = {
    "team1": "علي بن أبي طالب",
    "team2": "مصعب بن عمير",
    "team3": "عبدالله بن عمر",
    "team4": "عبدالله بن عباس",
    "team5": "أنس بن مالك"
  };
  return teamNames[team] || "None";
}

function getBuildingInfo(building) {
  var buildingInfos = {
    "بيت": { name: "بيت", icon: "fas fa-بيت" },
    "بقالة": { name: "بقالة", icon: "fas fa-shopping-cart" },
    "سوق": { name: "سوق", icon: "fas fa-archway" },
    "فندق": { name: "فندق", icon: "fas fa-h-square" },
    "مصنع": { name: "مصنع", icon: "fas fa-tractor" },
    "مجمع": { name: "مجمع", icon: "fas fa-فندق" }
  };
  return buildingInfos[building] || { name: "Unknown", icon: "fas fa-question-circle" };
}

function getButtonClass(team) {
  var buttonClasses = {
    "team1": "btn-danger",
    "team2": "btn-dark",
    "team3": "btn-primary",
    "team4": "btn-success",
    "team5": "btn-info"
  };
  return buttonClasses[team] || "btn-secondary";
}

function displayResults() {
  $("#results").html(
    `<h1 class='text-danger'>علي بن أبي طالب ${teamPoints[0]}</h1><br>
     <h1 class='text-dark'>مصعب بن عمير ${teamPoints[1]}</h1><br>
     <h1 class='text-primary'>عبدالله بن عمر ${teamPoints[2]}</h1><br>
     <h1 class='text-success'>عبدالله بن عباس ${teamPoints[3]}</h1><br>
     <h1 class='text-info'>أنس بن مالك ${teamPoints[4]}</h1>`
  );
}

function addPoints() {
  modifyPoints((a, b) => a + b);
}

function removePoints() {
  modifyPoints((a, b) => a - b);
}

function modifyPoints(operation) {
  for (let i = 0; i < 5; i++) {
    var inputVal = Number($(`#team${i + 1}Input`).val());
    if (!isNaN(inputVal)) {
      teamPoints[i] = operation(teamPoints[i], inputVal);
      $(`#team${i + 1}Input`).val('');
    }
  }
  displayResults();
}
