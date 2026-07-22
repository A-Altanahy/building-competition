/* ==========================================================================
   الأشبال - تحدي البناء - Main Application UI Controller
   ========================================================================== */

document.addEventListener('DOMContentLoaded', () => {
  const gameState = new GameState();
  const canvas = document.getElementById('isoCanvas');
  const renderer = new IsometricRenderer(canvas, gameState);

  // UI Elements
  const hudPanel = document.getElementById('hudTeamsPanel');
  const tooltip = document.getElementById('buildingTooltip');
  const modalOverlay = document.getElementById('buildingModal');
  const modalCellTitle = document.getElementById('modalCellTitle');
  const teamSelect = document.getElementById('modalTeamSelect');
  const btnConfirmBuild = document.getElementById('btnConfirmBuild');
  const btnDemolish = document.getElementById('btnDemolish');
  const btnEndRound = document.getElementById('btnEndRound');
  const btnUndoRound = document.getElementById('btnUndoRound');
  const roundBadge = document.getElementById('roundBadge');

  // Zoom Controls
  const btnZoomIn = document.getElementById('btnZoomIn');
  const btnZoomOut = document.getElementById('btnZoomOut');
  const btnZoomReset = document.getElementById('btnZoomReset');

  // Team Settings Modal
  const teamSettingsBtn = document.getElementById('btnTeamSettings');
  const teamSettingsModal = document.getElementById('teamSettingsModal');
  const teamSettingsContainer = document.getElementById('teamSettingsContainer');
  const btnAddTeam = document.getElementById('btnAddTeam');
  const btnSaveTeams = document.getElementById('btnSaveTeams');
  const btnCloseTeamSettings = document.getElementById('btnCloseTeamSettings');

  let selectedBuildingType = 'بيت';

  // Render initial HUD
  updateHUD();

  // Zoom Controls Handlers
  if (btnZoomIn) btnZoomIn.addEventListener('click', () => renderer.zoomIn());
  if (btnZoomOut) btnZoomOut.addEventListener('click', () => renderer.zoomOut());
  if (btnZoomReset) btnZoomReset.addEventListener('click', () => renderer.resetZoom());

  // ===== LEFT CLICK =====
  // 1. Empty square → open building placement menu modal
  // 2. Occupied building → show building info tooltip
  renderer.onCellClick = (cellIndex, screenX, screenY) => {
    const cell = gameState.board[cellIndex];

    if (cell && cell.building && cell.teamId) {
      // Occupied cell → show info tooltip
      showTooltip(cell, screenX, screenY);
    } else {
      // Empty cell → open building placement menu modal!
      hideTooltip();
      openBuildModal(cellIndex);
    }
  };

  // ===== RIGHT CLICK =====
  // Occupied building → open build/edit modal to change owner or demolish
  renderer.onCellRightClick = (cellIndex, screenX, screenY) => {
    const cell = gameState.board[cellIndex];

    if (cell && cell.building && cell.teamId) {
      hideTooltip();
      openBuildModal(cellIndex);
    }
  };

  // ===== Empty space click — deselect and hide tooltip =====
  renderer.onEmptyClick = () => {
    hideTooltip();
  };

  // Building Type Buttons in Modal
  document.querySelectorAll('.building-select-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.building-select-btn').forEach(b => b.classList.remove('selected'));
      btn.classList.add('selected');
      selectedBuildingType = btn.dataset.building;
    });
  });

  // Modal Action Buttons
  btnConfirmBuild.addEventListener('click', () => {
    if (renderer.selectedCellIndex) {
      const teamId = teamSelect.value;
      gameState.placeBuilding(renderer.selectedCellIndex, selectedBuildingType, teamId);
      closeBuildModal();
      updateHUD();
    }
  });

  btnDemolish.addEventListener('click', () => {
    if (renderer.selectedCellIndex) {
      gameState.removeBuilding(renderer.selectedCellIndex);
      closeBuildModal();
      hideTooltip();
      updateHUD();
    }
  });

  document.getElementById('btnCloseModal').addEventListener('click', closeBuildModal);

  // Round Management
  btnEndRound.addEventListener('click', () => {
    gameState.endRound();
    roundBadge.textContent = `الجولة ${gameState.currentRound}`;
    updateHUD();
  });

  btnUndoRound.addEventListener('click', () => {
    gameState.undoRound();
    roundBadge.textContent = `الجولة ${gameState.currentRound}`;
    updateHUD();
  });

  // ===== TEAM SETTINGS MODAL =====
  if (teamSettingsBtn) {
    teamSettingsBtn.addEventListener('click', openTeamSettingsModal);
  }
  if (btnCloseTeamSettings) {
    btnCloseTeamSettings.addEventListener('click', closeTeamSettingsModal);
  }
  if (btnAddTeam) {
    btnAddTeam.addEventListener('click', () => {
      const newId = 'team' + (gameState.teams.length + 1) + '_' + Date.now();
      gameState.teams.push({
        id: newId,
        name: 'فريق جديد',
        color: getRandomTeamColor(),
        balance: 1000,
        score: 0
      });
      renderTeamSettingsRows();
    });
  }
  if (btnSaveTeams) {
    btnSaveTeams.addEventListener('click', () => {
      saveTeamSettings();
      closeTeamSettingsModal();
      updateHUD();
    });
  }

  function openTeamSettingsModal() {
    renderTeamSettingsRows();
    teamSettingsModal.classList.add('show');
  }

  function closeTeamSettingsModal() {
    teamSettingsModal.classList.remove('show');
  }

  function renderTeamSettingsRows() {
    teamSettingsContainer.innerHTML = '';
    gameState.teams.forEach((team, idx) => {
      const row = document.createElement('div');
      row.className = 'team-settings-row';
      row.innerHTML = `
        <input type="color" class="team-color-picker" value="${team.color}" data-idx="${idx}">
        <input type="text" class="team-name-input" value="${team.name}" data-idx="${idx}" placeholder="اسم الفريق">
        <input type="number" class="team-balance-input" value="${team.balance}" data-idx="${idx}" min="0" step="100" title="الرصيد (د.ك)">
        <button class="btn-remove-team" data-idx="${idx}" title="حذف الفريق">
          <i class="fa-solid fa-trash"></i>
        </button>
      `;
      teamSettingsContainer.appendChild(row);
    });

    teamSettingsContainer.querySelectorAll('.btn-remove-team').forEach(btn => {
      btn.addEventListener('click', () => {
        const idx = parseInt(btn.dataset.idx);
        if (gameState.teams.length > 1) {
          gameState.teams.splice(idx, 1);
          renderTeamSettingsRows();
        }
      });
    });
  }

  function saveTeamSettings() {
    const nameInputs = teamSettingsContainer.querySelectorAll('.team-name-input');
    const colorInputs = teamSettingsContainer.querySelectorAll('.team-color-picker');
    const balanceInputs = teamSettingsContainer.querySelectorAll('.team-balance-input');

    nameInputs.forEach((input, idx) => {
      if (gameState.teams[idx]) {
        gameState.teams[idx].name = input.value || `فريق ${idx + 1}`;
      }
    });
    colorInputs.forEach((input, idx) => {
      if (gameState.teams[idx]) {
        gameState.teams[idx].color = input.value;
      }
    });
    balanceInputs.forEach((input, idx) => {
      if (gameState.teams[idx]) {
        gameState.teams[idx].balance = parseInt(input.value) || 0;
      }
    });
  }

  function getRandomTeamColor() {
    const colors = ['#E63946', '#457B9D', '#2A9D8F', '#E76F51', '#6A4C93', '#1982C4', '#FF595E', '#8AC926'];
    return colors[Math.floor(Math.random() * colors.length)];
  }

  // ===== HUD UPDATE =====
  function updateHUD() {
    hudPanel.innerHTML = '';
    gameState.teams.forEach((team, idx) => {
      const card = document.createElement('div');
      card.className = `team-card-hud ${idx === gameState.activeTeamIndex ? 'active-turn' : ''}`;
      card.style.setProperty('--team-color', team.color);

      card.innerHTML = `
        <div class="team-color-dot" style="background: ${team.color};"></div>
        <div class="team-info">
          <span class="team-name">${team.name}</span>
        </div>
        <div class="team-balance">${team.balance} د.ك</div>
      `;

      card.addEventListener('click', () => {
        gameState.activeTeamIndex = idx;
        updateHUD();
      });

      hudPanel.appendChild(card);
    });

    teamSelect.innerHTML = gameState.teams.map(t => 
      `<option value="${t.id}">${t.name}</option>`
    ).join('');
  }

  function openBuildModal(cellIndex) {
    const cell = gameState.board[cellIndex];
    modalCellTitle.textContent = `المربع #${cellIndex}`;

    if (cell.building) {
      selectedBuildingType = cell.building;
      document.querySelectorAll('.building-select-btn').forEach(b => {
        b.classList.toggle('selected', b.dataset.building === cell.building);
      });
    }
    if (cell.teamId) {
      teamSelect.value = cell.teamId;
    }

    btnDemolish.style.display = cell.building ? 'inline-flex' : 'none';
    modalOverlay.classList.add('show');
  }

  function closeBuildModal() {
    modalOverlay.classList.remove('show');
  }

  function showTooltip(cell, x, y) {
    const owner = gameState.teams.find(t => t.id === cell.teamId);
    const value = gameState.calculateCellValue(cell.index);
    const baseValue = gameState.buildingBaseValues[cell.building] || 0;
    const diff = value - baseValue;

    document.getElementById('tooltipTitle').textContent = `${cell.building} - ${owner ? owner.name : ''}`;
    document.getElementById('tooltipCellNum').textContent = `#${cell.index}`;
    document.getElementById('tooltipOwner').textContent = owner ? owner.name : 'غير مملوك';
    document.getElementById('tooltipYield').textContent = `${value} د.ك`;
    document.getElementById('tooltipBaseValue').textContent = `${baseValue} د.ك`;

    const modContainer = document.getElementById('tooltipModifier');
    if (diff > 0) {
      modContainer.className = 'modifier-tag boost';
      modContainer.textContent = `+${diff} د.ك زيادة (تأثير مجاور)`;
    } else if (diff < 0) {
      modContainer.className = 'modifier-tag penalty';
      modContainer.textContent = `${diff} د.ك خصم (تأثير مجاور)`;
    } else {
      modContainer.className = 'modifier-tag neutral';
      modContainer.textContent = 'لا يوجد تأثير';
    }

    tooltip.style.left = `${Math.min(window.innerWidth - 300, x + 15)}px`;
    tooltip.style.top = `${Math.min(window.innerHeight - 220, y + 15)}px`;
    tooltip.classList.add('show');
  }

  function hideTooltip() {
    tooltip.classList.remove('show');
  }

  document.addEventListener('click', (e) => {
    if (!canvas.contains(e.target) && !tooltip.contains(e.target)) {
      hideTooltip();
    }
  });
});
