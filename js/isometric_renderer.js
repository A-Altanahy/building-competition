/* ==========================================================================
   الأشبال - تحدي البناء - High-Res 2.5D Isometric Sandstone Oasis Board & VFX Engine
   ========================================================================== */

class IsometricRenderer {
  constructor(canvas, gameState) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.gameState = gameState;

    this.cols = 10;
    this.rows = 10;

    // Default tile dimensions
    this.tileWidth = 84;
    this.tileHeight = 44;
    this.tileDepth = 16;

    // Pan & Smooth Zoom State
    this.scale = 1.0;
    this.targetScale = 1.0;

    this.panX = 0;
    this.panY = 0;
    this.targetPanX = 0;
    this.targetPanY = 0;

    this.isDragging = false;
    this.dragStartX = 0;
    this.dragStartY = 0;
    this.dragStartPanX = 0;
    this.dragStartPanY = 0;

    this.hoveredCellIndex = null;
    this.selectedCellIndex = null;
    this.beamAnimTime = 0;

    // Callbacks
    this.onCellClick = null;       // Left click on a cell
    this.onCellRightClick = null;  // Right click on a cell
    this.onEmptyClick = null;      // Click on empty space

    // Load Transparent 3D Building Sprites (Official 4 buildings)
    this.buildingImages = {};
    this.loadBuildingImages();

    this.resizeCanvas();
    window.addEventListener('resize', () => this.resizeCanvas());

    this.initEventListeners();
    this.animate();
  }

  loadBuildingImages() {
    const buildings = {
      'بيت': 'assets/buildings/house.png',
      'بقالة': 'assets/buildings/grocery.png',
      'سوق': 'assets/buildings/market.png',
      'فندق': 'assets/buildings/hotel.png'
    };

    for (const [key, path] of Object.entries(buildings)) {
      const img = new Image();
      img.src = path + '?v=' + Date.now();
      this.buildingImages[key] = img;
    }
  }

  resizeCanvas() {
    const parent = this.canvas.parentElement;
    if (!parent) return;
    this.canvas.width = parent.clientWidth * window.devicePixelRatio;
    this.canvas.height = parent.clientHeight * window.devicePixelRatio;
    this.ctx.scale(window.devicePixelRatio, window.devicePixelRatio);

    const minDim = Math.min(parent.clientWidth, parent.clientHeight);
    this.tileWidth = Math.max(76, Math.min(104, minDim / 7.8));
    this.tileHeight = this.tileWidth * 0.52;
    this.tileDepth = this.tileWidth * 0.20;
  }

  getOrigin() {
    const parent = this.canvas.parentElement;
    const width = parent ? parent.clientWidth : 900;
    const height = parent ? parent.clientHeight : 700;

    const tw = this.tileWidth * this.scale;
    const th = this.tileHeight * this.scale;
    const centerCol = 5.5;
    const centerRow = 5.5;

    const gridCenterX = (centerCol - centerRow) * (tw / 2);
    const gridCenterY = (centerCol + centerRow) * (th / 2);

    return {
      x: width / 2 - gridCenterX + this.panX,
      y: height / 2 - gridCenterY + this.panY
    };
  }

  gridToIso(col, row) {
    const origin = this.getOrigin();
    const tw = this.tileWidth * this.scale;
    const th = this.tileHeight * this.scale;

    const x = (col - row) * (tw / 2) + origin.x;
    const y = (col + row) * (th / 2) + origin.y;
    return { x, y };
  }

  isoToGrid(screenX, screenY) {
    const origin = this.getOrigin();
    const tw = this.tileWidth * this.scale;
    const th = this.tileHeight * this.scale;

    const relX = screenX - origin.x;
    const relY = screenY - origin.y;

    const col = (relX / (tw / 2) + relY / (th / 2)) / 2;
    const row = (relY / (th / 2) - relX / (tw / 2)) / 2;

    const c = Math.floor(col) + 1;
    const r = Math.floor(row) + 1;

    if (c >= 1 && c <= 10 && r >= 1 && r <= 10) {
      return (r - 1) * 10 + c;
    }
    return null;
  }

  initEventListeners() {
    // Smooth Mouse Wheel Zoom
    this.canvas.addEventListener('wheel', (e) => {
      e.preventDefault();

      const rect = this.canvas.getBoundingClientRect();
      const mouseX = e.clientX - rect.left;
      const mouseY = e.clientY - rect.top;

      const parent = this.canvas.parentElement;
      const cx = parent ? parent.clientWidth / 2 : 450;
      const cy = parent ? parent.clientHeight / 2 : 350;

      const delta = -e.deltaY * 0.001;
      const zoomFactor = Math.pow(2, delta);
      const newScale = Math.max(0.4, Math.min(3.0, this.targetScale * zoomFactor));
      const scaleRatio = newScale / this.targetScale;

      this.targetPanX = this.targetPanX - (mouseX - cx) * (scaleRatio - 1) * 0.3;
      this.targetPanY = this.targetPanY - (mouseY - cy) * (scaleRatio - 1) * 0.3;

      this.targetScale = newScale;
    }, { passive: false });

    // Drag-to-Pan Handlers
    this.canvas.addEventListener('mousedown', (e) => {
      if (e.button === 0) {
        this.isDragging = false;
        this.dragStartX = e.clientX;
        this.dragStartY = e.clientY;
        this.dragStartPanX = this.targetPanX;
        this.dragStartPanY = this.targetPanY;
      }
    });

    window.addEventListener('mousemove', (e) => {
      if (this.dragStartX !== 0) {
        const dx = e.clientX - this.dragStartX;
        const dy = e.clientY - this.dragStartY;
        if (Math.abs(dx) > 3 || Math.abs(dy) > 3) {
          this.isDragging = true;
          this.targetPanX = this.dragStartPanX + dx;
          this.targetPanY = this.dragStartPanY + dy;
        }
      }

      // Tile Hover Detection
      const rect = this.canvas.getBoundingClientRect();
      const mouseX = e.clientX - rect.left;
      const mouseY = e.clientY - rect.top;
      const idx = this.isoToGrid(mouseX, mouseY);
      if (idx !== this.hoveredCellIndex) {
        this.hoveredCellIndex = idx;
      }
    });

    window.addEventListener('mouseup', () => {
      this.dragStartX = 0;
      this.dragStartY = 0;
    });

    this.canvas.addEventListener('mouseleave', () => {
      this.hoveredCellIndex = null;
    });

    // LEFT CLICK — show info tooltip (if building) or open build menu (if empty)
    this.canvas.addEventListener('click', (e) => {
      if (!this.isDragging) {
        const rect = this.canvas.getBoundingClientRect();
        const mouseX = e.clientX - rect.left;
        const mouseY = e.clientY - rect.top;

        const idx = this.isoToGrid(mouseX, mouseY);
        if (idx) {
          this.selectedCellIndex = idx;
          if (this.onCellClick) {
            this.onCellClick(idx, e.clientX, e.clientY);
          }
        } else {
          this.selectedCellIndex = null;
          if (this.onEmptyClick) {
            this.onEmptyClick();
          }
        }
      }
    });

    // RIGHT CLICK — open edit modal (only if cell has a building)
    this.canvas.addEventListener('contextmenu', (e) => {
      e.preventDefault();
      const rect = this.canvas.getBoundingClientRect();
      const mouseX = e.clientX - rect.left;
      const mouseY = e.clientY - rect.top;

      const idx = this.isoToGrid(mouseX, mouseY);
      if (idx) {
        this.selectedCellIndex = idx;
        if (this.onCellRightClick) {
          this.onCellRightClick(idx, e.clientX, e.clientY);
        }
      }
    });
  }

  zoomIn() {
    this.targetScale = Math.min(3.0, this.targetScale * 1.25);
  }

  zoomOut() {
    this.targetScale = Math.max(0.4, this.targetScale / 1.25);
  }

  resetZoom() {
    this.targetScale = 1.0;
    this.targetPanX = 0;
    this.targetPanY = 0;
  }

  animate() {
    this.scale += (this.targetScale - this.scale) * 0.12;
    this.panX += (this.targetPanX - this.panX) * 0.15;
    this.panY += (this.targetPanY - this.panY) * 0.15;

    this.beamAnimTime += 0.03;
    this.render();
    requestAnimationFrame(() => this.animate());
  }

  render() {
    const parent = this.canvas.parentElement;
    const width = parent ? parent.clientWidth : 900;
    const height = parent ? parent.clientHeight : 700;

    this.ctx.clearRect(0, 0, width, height);

    // 1. Draw Team Influence Overlays on 8 surrounding tiles around Souq
    this.renderInfluenceZones();

    // 2. Render Grid Tiles in Z-Order (Back-to-Front)
    for (let r = 1; r <= 10; r++) {
      for (let c = 1; c <= 10; c++) {
        const index = (r - 1) * 10 + c;
        const cell = this.gameState.board[index];
        const isHovered = this.hoveredCellIndex === index;
        const isSelected = this.selectedCellIndex === index;

        this.renderTile(c, r, cell, isHovered, isSelected);
      }
    }

    // 3. Render Connection Beams (BEHIND buildings, on top of tiles)
    this.renderConnectionBeams();

    // 4. Render 3D Building Sprites in Z-Order (IN FRONT of effect lines)
    for (let r = 1; r <= 10; r++) {
      for (let c = 1; c <= 10; c++) {
        const index = (r - 1) * 10 + c;
        const cell = this.gameState.board[index];
        const isHovered = this.hoveredCellIndex === index;
        const isSelected = this.selectedCellIndex === index;

        if (cell.building && cell.teamId) {
          this.renderBuilding(c, r, cell, isHovered || isSelected);
        }
      }
    }
  }

  // ==================== INFLUENCE ZONE SHADOWS & SOUQ CLICK HIGHLIGHT ====================
  // Highlights the 8 affected surrounding squares when Souq is clicked
  renderInfluenceZones() {
    const s = this.scale;
    const tw = this.tileWidth * s;
    const th = this.tileHeight * s;

    for (let i = 1; i <= 100; i++) {
      const cell = this.gameState.board[i];
      if (!cell.building || !cell.teamId) continue;
      if (cell.building !== 'سوق') continue;

      const ownerTeam = this.gameState.teams.find(t => t.id === cell.teamId);
      if (!ownerTeam) continue;

      // Check if this Souq is currently selected/clicked by user
      const isSelectedSouq = (this.selectedCellIndex === i);
      const surroundings = this.gameState.getSurroundingIndices(i);

      for (const sIdx of surroundings) {
        const sRow = Math.ceil(sIdx / 10);
        const sCol = (sIdx - 1) % 10 + 1;
        const sIso = this.gridToIso(sCol, sRow);

        this.ctx.save();
        this.ctx.beginPath();
        this.ctx.moveTo(sIso.x, sIso.y - th / 2);
        this.ctx.lineTo(sIso.x + tw / 2, sIso.y);
        this.ctx.lineTo(sIso.x, sIso.y + th / 2);
        this.ctx.lineTo(sIso.x - tw / 2, sIso.y);
        this.ctx.closePath();

        if (isSelectedSouq) {
          // Vibrant Cyan Glowing Highlight when Souq is clicked
          this.ctx.fillStyle = 'rgba(0, 245, 255, 0.35)';
          this.ctx.fill();

          this.ctx.strokeStyle = '#00F5FF';
          this.ctx.shadowColor = '#00F5FF';
          this.ctx.shadowBlur = 14;
          this.ctx.lineWidth = 2.5;
          this.ctx.stroke();
        } else {
          // Subtle team overlay
          this.ctx.fillStyle = this.adjustColorOpacity(ownerTeam.color, 0.20);
          this.ctx.fill();

          this.ctx.strokeStyle = this.adjustColorOpacity(ownerTeam.color, 0.40);
          this.ctx.lineWidth = 1.5;
          this.ctx.stroke();
        }
        this.ctx.restore();
      }
    }
  }

  // ==================== ELEGANT SANDSTONE OASIS TILE RENDERER ====================
  renderTile(col, row, cell, isHovered, isSelected) {
    const { x, y } = this.gridToIso(col, row);
    const tw = this.tileWidth * this.scale;
    const th = this.tileHeight * this.scale;
    const td = this.tileDepth * this.scale;

    const elevation = (isSelected ? 10 : (isHovered ? 5 : 0)) * this.scale;
    const topY = y - elevation;

    const ownerTeam = cell.teamId ? this.gameState.teams.find(t => t.id === cell.teamId) : null;

    // 3D Voxel Sandstone Side Walls
    // Left Wall
    this.ctx.beginPath();
    this.ctx.moveTo(x - tw / 2, topY);
    this.ctx.lineTo(x, topY + th / 2);
    this.ctx.lineTo(x, topY + th / 2 + td);
    this.ctx.lineTo(x - tw / 2, topY + td);
    this.ctx.closePath();
    this.ctx.fillStyle = ownerTeam ? this.darkenColor(ownerTeam.color, 0.52) : '#A68A68';
    this.ctx.fill();

    // Right Wall
    this.ctx.beginPath();
    this.ctx.moveTo(x, topY + th / 2);
    this.ctx.lineTo(x + tw / 2, topY);
    this.ctx.lineTo(x + tw / 2, topY + td);
    this.ctx.lineTo(x, topY + th / 2 + td);
    this.ctx.closePath();
    this.ctx.fillStyle = ownerTeam ? this.darkenColor(ownerTeam.color, 0.38) : '#8C7252';
    this.ctx.fill();

    // Top Rim Line
    this.ctx.beginPath();
    this.ctx.moveTo(x - tw / 2, topY);
    this.ctx.lineTo(x, topY + th / 2);
    this.ctx.lineTo(x + tw / 2, topY);
    this.ctx.strokeStyle = ownerTeam ? ownerTeam.color : '#CBB596';
    this.ctx.lineWidth = 1.2 * this.scale;
    this.ctx.stroke();

    // Top Face Polygon
    this.ctx.beginPath();
    this.ctx.moveTo(x, topY - th / 2);
    this.ctx.lineTo(x + tw / 2, topY);
    this.ctx.lineTo(x, topY + th / 2);
    this.ctx.lineTo(x - tw / 2, topY);
    this.ctx.closePath();

    // Checkerboard Sandstone Fill
    if (ownerTeam) {
      this.ctx.fillStyle = this.adjustColorOpacity(ownerTeam.color, 0.65);
    } else if ((col + row) % 2 === 0) {
      this.ctx.fillStyle = '#E5D9C3';
    } else {
      this.ctx.fillStyle = '#D8C8AF';
    }
    this.ctx.fill();

    // Subtle Glossy Edge Shine
    this.ctx.save();
    this.ctx.beginPath();
    this.ctx.moveTo(x, topY - th / 2);
    this.ctx.lineTo(x - tw / 2, topY);
    this.ctx.lineTo(x, topY + th * 0.12);
    this.ctx.lineTo(x + tw * 0.12, topY - th * 0.15);
    this.ctx.closePath();
    this.ctx.fillStyle = 'rgba(255, 255, 255, 0.25)';
    this.ctx.fill();
    this.ctx.restore();

    // Tile Grid Lines
    this.ctx.strokeStyle = ownerTeam ? ownerTeam.color : 'rgba(140, 114, 82, 0.28)';
    this.ctx.lineWidth = isSelected ? 2.5 : (isHovered ? 2.0 : 1.0);
    this.ctx.stroke();

    // Selection & Hover Outlines
    if (isSelected) {
      this.ctx.beginPath();
      this.ctx.moveTo(x, topY - th / 2);
      this.ctx.lineTo(x + tw / 2, topY);
      this.ctx.lineTo(x, topY + th / 2);
      this.ctx.lineTo(x - tw / 2, topY);
      this.ctx.closePath();
      this.ctx.strokeStyle = '#00F5FF';
      this.ctx.shadowColor = '#00F5FF';
      this.ctx.shadowBlur = 14;
      this.ctx.lineWidth = 2.8;
      this.ctx.stroke();
      this.ctx.shadowBlur = 0;
    } else if (isHovered) {
      this.ctx.beginPath();
      this.ctx.moveTo(x, topY - th / 2);
      this.ctx.lineTo(x + tw / 2, topY);
      this.ctx.lineTo(x, topY + th / 2);
      this.ctx.lineTo(x - tw / 2, topY);
      this.ctx.closePath();
      this.ctx.strokeStyle = '#FF6B00';
      this.ctx.shadowColor = '#FF6B00';
      this.ctx.shadowBlur = 12;
      this.ctx.lineWidth = 2.2;
      this.ctx.stroke();
      this.ctx.shadowBlur = 0;
    }

    // Cell Index Number
    const fontSize = Math.max(9, Math.round(11 * this.scale));
    this.ctx.font = `700 ${fontSize}px Cairo, sans-serif`;
    this.ctx.fillStyle = ownerTeam ? '#FFFFFF' : '#4A3C2C';
    this.ctx.textAlign = 'center';
    this.ctx.textBaseline = 'middle';
    this.ctx.fillText(cell.index, x, topY);
  }

  // ==================== ACCURATELY CENTERED & COMPACT BUILDING RENDERING ====================
  renderBuilding(col, row, cell, highlight) {
    const { x, y } = this.gridToIso(col, row);
    const tw = this.tileWidth * this.scale;
    const th = this.tileHeight * this.scale;

    const elevation = (highlight ? 8 : 0) * this.scale;
    const topY = y - elevation;

    const img = this.buildingImages[cell.building];
    // Slightly smaller building sprite size (54% of tile width) so grid stays clean & spacious
    const spriteSize = tw * 0.54;

    // 1. Draw Floor Drop Shadow right in tile center
    this.ctx.save();
    this.ctx.beginPath();
    this.ctx.ellipse(x, topY, tw * 0.32, th * 0.32, 0, 0, Math.PI * 2);
    this.ctx.fillStyle = 'rgba(74, 60, 44, 0.28)';
    this.ctx.fill();

    // 2. Draw Transparent 3D Building Sprite centered accurately
    if (img && img.complete && img.naturalWidth > 0) {
      const drawX = x - spriteSize / 2;
      const drawY = topY - spriteSize * 0.78;
      this.ctx.drawImage(img, drawX, drawY, spriteSize, spriteSize);
    } else {
      this.drawVectorBuildingFallback(x, topY - th * 0.4, tw * 0.45, cell.building);
    }

    this.ctx.restore();
  }

  drawVectorBuildingFallback(x, y, s, buildingType) {
    const icons = { 'بيت': '🏠', 'بقالة': '🛒', 'سوق': '🕌', 'فندق': '🏨' };
    this.ctx.font = `${Math.round(s * 1.2)}px sans-serif`;
    this.ctx.textAlign = 'center';
    this.ctx.textBaseline = 'middle';
    this.ctx.fillText(icons[buildingType] || '🏠', x, y);
  }

  // ==================== SEMI-TRANSPARENT EFFECT BEAMS (BEHIND BUILDINGS) ====================
  // Blue (#0077FF) for positive boost, Red (#FF3B30) for negative penalty
  renderConnectionBeams() {
    for (let i = 1; i <= 100; i++) {
      const cell = this.gameState.board[i];
      if (!cell.building || !cell.teamId) continue;
      if (cell.building !== 'سوق') continue;

      const row = Math.ceil(i / 10);
      const col = (i - 1) % 10 + 1;
      const src = this.gridToIso(col, row);

      const surroundings = this.gameState.getSurroundingIndices(i);
      for (const targetIdx of surroundings) {
        const targetCell = this.gameState.board[targetIdx];
        if (!targetCell.building || !targetCell.teamId) continue;

        const tRow = Math.ceil(targetIdx / 10);
        const tCol = (targetIdx - 1) % 10 + 1;
        const dest = this.gridToIso(tCol, tRow);

        const baseValue = this.gameState.buildingBaseValues[targetCell.building] || 0;
        const actualValue = this.gameState.calculateCellValue(targetIdx);
        const isPositive = actualValue >= baseValue;

        // Blue (#0077FF) for positive boost, Red (#FF3B30) for negative penalty
        const color = isPositive ? '#0077FF' : '#FF3B30';

        this.drawEnergyFlow(src, dest, color, i + targetIdx);
      }
    }
  }

  drawEnergyFlow(src, dest, color, seed) {
    const ctx = this.ctx;
    const s = this.scale;
    const t = this.beamAnimTime;

    const srcX = src.x;
    const srcY = src.y - 6 * s;
    const destX = dest.x;
    const destY = dest.y - 6 * s;

    const dx = destX - srcX;
    const dy = destY - srcY;
    const dist = Math.sqrt(dx * dx + dy * dy);
    if (dist < 1) return;

    const perpX = -dy / dist;
    const perpY = dx / dist;

    ctx.save();

    // ---- 1. Wide Outer Glow Layer ----
    ctx.beginPath();
    ctx.moveTo(srcX, srcY);
    ctx.lineTo(destX, destY);
    ctx.strokeStyle = color;
    ctx.globalAlpha = 0.15;
    ctx.lineWidth = 10 * s;
    ctx.shadowColor = color;
    ctx.shadowBlur = 12;
    ctx.lineCap = 'round';
    ctx.stroke();

    // ---- 2. Main Vibrant Beam Layer ----
    ctx.beginPath();
    ctx.moveTo(srcX, srcY);
    ctx.lineTo(destX, destY);
    ctx.globalAlpha = 0.50;
    ctx.lineWidth = 3.5 * s;
    ctx.shadowBlur = 6;
    ctx.stroke();

    // ---- 3. White Hot Core Line ----
    ctx.beginPath();
    ctx.moveTo(srcX, srcY);
    ctx.lineTo(destX, destY);
    ctx.strokeStyle = '#FFFFFF';
    ctx.globalAlpha = 0.60;
    ctx.lineWidth = 1.5 * s;
    ctx.stroke();

    // ---- 4. Animated Electric Tendril Crackle ----
    const segments = 6;
    ctx.beginPath();
    ctx.moveTo(srcX, srcY);

    for (let i = 1; i < segments; i++) {
      const frac = i / segments;
      const baseX = srcX + dx * frac;
      const baseY = srcY + dy * frac;

      const jitter = Math.sin(t * 25 + i * 4.3 + seed) * 3 * s * Math.sin(frac * Math.PI);
      ctx.lineTo(baseX + perpX * jitter, baseY + perpY * jitter);
    }
    ctx.lineTo(destX, destY);

    ctx.strokeStyle = color;
    ctx.globalAlpha = 0.40;
    ctx.lineWidth = 1.0 * s;
    ctx.stroke();

    ctx.globalAlpha = 1.0;
    ctx.shadowBlur = 0;
    ctx.restore();
  }

  adjustColorOpacity(hex, opacity) {
    if (!hex || !hex.startsWith('#')) return `rgba(212, 175, 55, ${opacity})`;
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${opacity})`;
  }

  darkenColor(hex, factor) {
    if (!hex || !hex.startsWith('#')) return '#111';
    const r = Math.round(parseInt(hex.slice(1, 3), 16) * factor);
    const g = Math.round(parseInt(hex.slice(3, 5), 16) * factor);
    const b = Math.round(parseInt(hex.slice(5, 7), 16) * factor);
    return `rgb(${r}, ${g}, ${b})`;
  }
}
