# Electric CSS Micro-Animation Techniques

Production-ready CSS for dark-theme landing pages. All techniques use a base of `#0a0a0f` background with neon accents: pink `#ff2d78`, green `#39ff14`, yellow `#ffe600`, cyan `#00f0ff`.

---

## 1. Holographic / Shimmer Gradient Text

The technique Linear, Stripe, and Vercel use: an animated `linear-gradient` background clipped to text via `-webkit-background-clip: text`, with `background-size` wider than the element so `background-position` can be animated across it.

```css
.shimmer-text {
  font-size: 4rem;
  font-weight: 800;
  background: linear-gradient(
    120deg,
    #ff2d78 0%,
    #ffe600 25%,
    #00f0ff 50%,
    #39ff14 75%,
    #ff2d78 100%
  );
  background-size: 200% 100%;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  animation: shimmer-shift 3s linear infinite;
}

@keyframes shimmer-shift {
  0% { background-position: 200% center; }
  100% { background-position: -200% center; }
}
```

**Variant: single-color shine sweep (Vercel style)**

```css
.shine-text {
  font-size: 3.5rem;
  font-weight: 700;
  color: #e0e0e0;
  background: linear-gradient(
    110deg,
    transparent 25%,
    rgba(255, 255, 255, 0.5) 50%,
    transparent 75%
  );
  background-size: 250% 100%;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  animation: shine-sweep 4s ease-in-out infinite;
}

@keyframes shine-sweep {
  0% { background-position: 200% center; }
  100% { background-position: -200% center; }
}
```

**Variant: holographic foil (conic gradient blend)**

```css
.holo-text {
  font-size: 4rem;
  font-weight: 800;
  background:
    conic-gradient(from 0deg at 50% 50%, #ff2d78, #ffe600, #00f0ff, #39ff14, #ff2d78),
    linear-gradient(90deg, #ff2d78, #00f0ff);
  background-blend-mode: color-burn;
  background-size: 150% 150%;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  animation: holo-rotate 6s linear infinite;
}

@keyframes holo-rotate {
  0% { background-position: 0% 0%; }
  50% { background-position: 100% 100%; }
  100% { background-position: 0% 0%; }
}
```

---

## 2. Glow Effects on Buttons

### Pulsing neon glow

```css
.glow-btn {
  padding: 14px 32px;
  font-size: 1rem;
  font-weight: 600;
  color: #fff;
  background: #ff2d78;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  animation: neon-pulse 2s ease-in-out infinite;
}

@keyframes neon-pulse {
  0%, 100% {
    box-shadow:
      0 0 8px rgba(255, 45, 120, 0.4),
      0 0 20px rgba(255, 45, 120, 0.2),
      0 0 40px rgba(255, 45, 120, 0.1);
  }
  50% {
    box-shadow:
      0 0 12px rgba(255, 45, 120, 0.6),
      0 0 30px rgba(255, 45, 120, 0.4),
      0 0 60px rgba(255, 45, 120, 0.2),
      0 0 100px rgba(255, 45, 120, 0.1);
  }
}
```

### Shimmer sweep (light bar crossing the button)

```css
.shimmer-btn {
  position: relative;
  padding: 14px 32px;
  font-size: 1rem;
  font-weight: 600;
  color: #fff;
  background: linear-gradient(135deg, #ff2d78, #c4004e);
  border: none;
  border-radius: 8px;
  overflow: hidden;
  cursor: pointer;
}

.shimmer-btn::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 60%;
  height: 100%;
  background: linear-gradient(
    120deg,
    transparent 0%,
    rgba(255, 255, 255, 0.08) 30%,
    rgba(255, 255, 255, 0.25) 50%,
    rgba(255, 255, 255, 0.08) 70%,
    transparent 100%
  );
  animation: btn-shimmer 3s ease-in-out infinite;
}

@keyframes btn-shimmer {
  0% { left: -100%; }
  20% { left: 120%; }
  100% { left: 120%; }  /* pause between sweeps */
}
```

### Combined: glow + sweep

```css
.ultimate-btn {
  position: relative;
  padding: 16px 36px;
  font-size: 1rem;
  font-weight: 700;
  color: #fff;
  background: linear-gradient(135deg, #ff2d78, #c4004e);
  border: 1px solid rgba(255, 45, 120, 0.3);
  border-radius: 10px;
  overflow: hidden;
  cursor: pointer;
  transition: transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1),
              box-shadow 0.2s ease;
  animation: neon-pulse 2s ease-in-out infinite;
}

.ultimate-btn::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 60%;
  height: 100%;
  background: linear-gradient(
    120deg,
    transparent,
    rgba(255, 255, 255, 0.2),
    transparent
  );
  animation: btn-shimmer 4s ease-in-out infinite;
}

.ultimate-btn:hover {
  transform: translateY(-2px) scale(1.02);
  box-shadow:
    0 0 20px rgba(255, 45, 120, 0.5),
    0 0 60px rgba(255, 45, 120, 0.25);
}

.ultimate-btn:active {
  transform: translateY(0) scale(0.98);
}
```

---

## 3. Floating Particles (Pure CSS, no canvas)

20-30 particles using individual elements with randomized size, speed, opacity, and drift. For production, use a preprocessor loop or generate the HTML with JS once on load -- the animation itself is pure CSS.

### HTML structure (generate with a loop)

```html
<div class="particles">
  <span class="dot" style="--size:3px; --x:12%; --y:80%; --dur:18s; --delay:0s; --drift:40px; --opacity:0.3;"></span>
  <span class="dot" style="--size:2px; --x:25%; --y:90%; --dur:22s; --delay:-4s; --drift:-30px; --opacity:0.5;"></span>
  <span class="dot" style="--size:4px; --x:40%; --y:85%; --dur:15s; --delay:-8s; --drift:50px; --opacity:0.2;"></span>
  <span class="dot" style="--size:2px; --x:55%; --y:95%; --dur:20s; --delay:-2s; --drift:-20px; --opacity:0.6;"></span>
  <span class="dot" style="--size:5px; --x:70%; --y:88%; --dur:25s; --delay:-10s; --drift:35px; --opacity:0.15;"></span>
  <span class="dot" style="--size:3px; --x:85%; --y:82%; --dur:17s; --delay:-6s; --drift:-45px; --opacity:0.4;"></span>
  <!-- ... repeat 20-30 times with varied values -->
</div>
```

### CSS

```css
.particles {
  position: fixed;
  inset: 0;
  overflow: hidden;
  pointer-events: none;
  z-index: 0;
}

.dot {
  position: absolute;
  left: var(--x);
  bottom: -10px;
  width: var(--size);
  height: var(--size);
  background: radial-gradient(circle, rgba(0, 240, 255, var(--opacity)) 0%, transparent 70%);
  border-radius: 50%;
  animation: float-up var(--dur) linear var(--delay) infinite;
}

@keyframes float-up {
  0% {
    transform: translateY(0) translateX(0);
    opacity: 0;
  }
  10% {
    opacity: 1;
  }
  90% {
    opacity: 1;
  }
  100% {
    transform: translateY(-110vh) translateX(var(--drift));
    opacity: 0;
  }
}
```

### One-time JS generator (paste once, never runs again in animation)

```html
<script>
const c = document.querySelector('.particles');
for (let i = 0; i < 25; i++) {
  const d = document.createElement('span');
  d.className = 'dot';
  d.style.cssText = `
    --size:${1 + Math.random() * 4}px;
    --x:${Math.random() * 100}%;
    --y:${70 + Math.random() * 30}%;
    --dur:${12 + Math.random() * 18}s;
    --delay:${-Math.random() * 20}s;
    --drift:${-50 + Math.random() * 100}px;
    --opacity:${0.15 + Math.random() * 0.5};
  `;
  c.appendChild(d);
}
</script>
```

### Depth variant (blur for parallax feel)

```css
.dot--far {
  filter: blur(1px);
  animation-duration: calc(var(--dur) * 1.5);
}

.dot--near {
  filter: blur(0);
  animation-duration: calc(var(--dur) * 0.7);
}
```

---

## 4. Cursor Glow Trail

Minimal JS (12 lines) that sets CSS custom properties. The glow itself is pure CSS.

### CSS

```css
body {
  --glow-x: 50%;
  --glow-y: 50%;
}

.cursor-glow {
  position: fixed;
  inset: 0;
  pointer-events: none;
  z-index: 9999;
  background: radial-gradient(
    300px circle at var(--glow-x) var(--glow-y),
    rgba(0, 240, 255, 0.07) 0%,
    rgba(255, 45, 120, 0.03) 40%,
    transparent 70%
  );
  transition: background 0.15s ease;
}
```

### JS (12 lines)

```js
const glow = document.querySelector('.cursor-glow');
document.addEventListener('mousemove', (e) => {
  glow.style.setProperty('--glow-x', e.clientX + 'px');
  glow.style.setProperty('--glow-y', e.clientY + 'px');
});
```

### HTML

```html
<div class="cursor-glow"></div>
```

### Variant: element-specific hover glow (cards, etc.)

```css
.card {
  position: relative;
  overflow: hidden;
}

.card::before {
  content: '';
  position: absolute;
  inset: 0;
  background: radial-gradient(
    400px circle at var(--mouse-x, 50%) var(--mouse-y, 50%),
    rgba(0, 240, 255, 0.1),
    transparent 60%
  );
  opacity: 0;
  transition: opacity 0.3s ease;
  pointer-events: none;
}

.card:hover::before {
  opacity: 1;
}
```

```js
document.querySelectorAll('.card').forEach(card => {
  card.addEventListener('mousemove', (e) => {
    const r = card.getBoundingClientRect();
    card.style.setProperty('--mouse-x', (e.clientX - r.left) + 'px');
    card.style.setProperty('--mouse-y', (e.clientY - r.top) + 'px');
  });
});
```

---

## 5. Spring / Bounce Animations

### The cubic-bezier values

```css
/* Gentle spring overshoot -- best for enter/appear */
--spring-enter: cubic-bezier(0.34, 1.56, 0.64, 1);

/* Bouncy spring -- best for hover/pop effects */
--spring-bounce: cubic-bezier(0.68, -0.55, 0.265, 1.55);

/* Snappy settle -- best for click feedback */
--spring-snap: cubic-bezier(0.22, 1.5, 0.36, 1);

/* Rubber band -- best for overscroll/pull effects */
--spring-rubber: cubic-bezier(0.175, 0.885, 0.32, 1.275);

/* Smooth decelerate -- best for slide-in */
--spring-smooth: cubic-bezier(0.16, 1, 0.3, 1);
```

### Usage patterns

```css
/* Element entering the viewport */
.enter-up {
  opacity: 0;
  transform: translateY(30px);
  transition: opacity 0.5s ease, transform 0.6s var(--spring-enter);
}

.enter-up.visible {
  opacity: 1;
  transform: translateY(0);
}

/* Hover scale with spring */
.hover-spring {
  transition: transform 0.4s var(--spring-bounce);
}

.hover-spring:hover {
  transform: scale(1.06);
}

/* Click squish */
.click-spring {
  transition: transform 0.15s var(--spring-snap);
}

.click-spring:active {
  transform: scale(0.94);
}
```

### Modern alternative: CSS linear() for multi-bounce

```css
/* True multi-bounce spring using linear() -- works in Chrome 113+, FF, Safari 17.2+ */
.true-spring {
  transition: transform 0.6s linear(
    0, 0.009, 0.035 2.1%, 0.141, 0.281 6.7%,
    0.723 12.9%, 0.938 16.7%, 1.017, 1.077,
    1.121 24%, 1.149 27.3%, 1.159, 1.163,
    1.161, 1.154 36.8%, 1.067 44.7%,
    1.019 50.6%, 1.004 55%, 0.996 60.4%,
    1 67.3%, 1.003 76%, 1
  );
}
```

### Intersection Observer for scroll-triggered springs (10 lines)

```js
const obs = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      e.target.classList.add('visible');
      obs.unobserve(e.target);
    }
  });
}, { threshold: 0.15 });

document.querySelectorAll('.enter-up').forEach(el => obs.observe(el));
```

---

## 6. Screen Glow Effect (Device Casting Light)

A MacBook-style screen element that casts colored light onto its surroundings using layered pseudo-elements and radial gradients.

```css
.screen-wrapper {
  position: relative;
  display: flex;
  justify-content: center;
  padding: 80px 0;
}

/* The glow cast BEHIND the screen */
.screen-wrapper::before {
  content: '';
  position: absolute;
  top: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 120%;
  height: 100%;
  background: radial-gradient(
    ellipse 60% 50% at 50% 30%,
    rgba(0, 240, 255, 0.15) 0%,
    rgba(255, 45, 120, 0.08) 30%,
    transparent 70%
  );
  filter: blur(60px);
  z-index: 0;
  animation: screen-glow-shift 8s ease-in-out infinite;
}

/* The screen itself */
.screen {
  position: relative;
  z-index: 1;
  width: 680px;
  max-width: 90vw;
  aspect-ratio: 16 / 10;
  background: #111118;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  overflow: hidden;
  box-shadow:
    0 0 0 1px rgba(255, 255, 255, 0.05),
    0 20px 60px rgba(0, 0, 0, 0.5),
    0 0 120px rgba(0, 240, 255, 0.08);
}

/* Animated color-shifting glow */
@keyframes screen-glow-shift {
  0%, 100% {
    background: radial-gradient(
      ellipse 60% 50% at 50% 30%,
      rgba(0, 240, 255, 0.15) 0%,
      rgba(255, 45, 120, 0.08) 30%,
      transparent 70%
    );
  }
  33% {
    background: radial-gradient(
      ellipse 60% 50% at 50% 30%,
      rgba(255, 45, 120, 0.15) 0%,
      rgba(255, 230, 0, 0.08) 30%,
      transparent 70%
    );
  }
  66% {
    background: radial-gradient(
      ellipse 60% 50% at 50% 30%,
      rgba(57, 255, 20, 0.12) 0%,
      rgba(0, 240, 255, 0.08) 30%,
      transparent 70%
    );
  }
}
```

### Variant: use @property for smooth color interpolation

```css
@property --glow-color-1 {
  syntax: '<color>';
  inherits: false;
  initial-value: rgba(0, 240, 255, 0.15);
}

@property --glow-color-2 {
  syntax: '<color>';
  inherits: false;
  initial-value: rgba(255, 45, 120, 0.08);
}

.screen-wrapper::before {
  background: radial-gradient(
    ellipse 60% 50% at 50% 30%,
    var(--glow-color-1) 0%,
    var(--glow-color-2) 40%,
    transparent 70%
  );
  filter: blur(60px);
  animation: glow-colors 8s ease-in-out infinite;
}

@keyframes glow-colors {
  0%, 100% {
    --glow-color-1: rgba(0, 240, 255, 0.15);
    --glow-color-2: rgba(255, 45, 120, 0.08);
  }
  33% {
    --glow-color-1: rgba(255, 45, 120, 0.15);
    --glow-color-2: rgba(255, 230, 0, 0.08);
  }
  66% {
    --glow-color-1: rgba(57, 255, 20, 0.12);
    --glow-color-2: rgba(0, 240, 255, 0.08);
  }
}
```

The `@property` version produces true smooth color transitions between gradient stops, rather than discrete jumps. It requires Chrome 85+, Safari 15.4+, Firefox 128+.

---

## 7. Breathing / Pulsing Elements

### Subtle breathing (for badges, status dots, icons)

```css
.breathe {
  animation: breathe 4s ease-in-out infinite;
}

@keyframes breathe {
  0%, 100% {
    transform: scale(1);
    opacity: 0.8;
  }
  50% {
    transform: scale(1.04);
    opacity: 1;
  }
}
```

### Live status dot

```css
.live-dot {
  width: 8px;
  height: 8px;
  background: #39ff14;
  border-radius: 50%;
  position: relative;
}

.live-dot::after {
  content: '';
  position: absolute;
  inset: -4px;
  border-radius: 50%;
  background: rgba(57, 255, 20, 0.3);
  animation: dot-pulse 2s ease-in-out infinite;
}

@keyframes dot-pulse {
  0%, 100% {
    transform: scale(1);
    opacity: 0.6;
  }
  50% {
    transform: scale(2.2);
    opacity: 0;
  }
}
```

### Breathing glow ring (for hero elements, avatars, logos)

```css
.glow-ring {
  position: relative;
  display: inline-flex;
}

.glow-ring::before {
  content: '';
  position: absolute;
  inset: -3px;
  border-radius: inherit;
  background: conic-gradient(from 0deg, #ff2d78, #ffe600, #00f0ff, #39ff14, #ff2d78);
  z-index: -1;
  animation: ring-breathe 3s ease-in-out infinite;
  filter: blur(8px);
}

@keyframes ring-breathe {
  0%, 100% {
    opacity: 0.4;
    transform: scale(1);
  }
  50% {
    opacity: 0.8;
    transform: scale(1.06);
  }
}
```

### Floating hover (for cards, feature blocks)

```css
.float {
  animation: gentle-float 6s ease-in-out infinite;
}

@keyframes gentle-float {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-8px);
  }
}
```

---

## 8. Testimonial Quotes Without Boxes

Premium social proof: no card borders, no backgrounds. Big quote text, gradient-highlighted keywords, floating layout.

```css
.testimonial-section {
  padding: 120px 24px;
  text-align: center;
  max-width: 900px;
  margin: 0 auto;
}

.testimonial-quote {
  font-size: clamp(1.5rem, 4vw, 2.8rem);
  font-weight: 300;
  line-height: 1.4;
  color: rgba(255, 255, 255, 0.85);
  letter-spacing: -0.02em;
  position: relative;
}

/* Giant decorative quote mark */
.testimonial-quote::before {
  content: '\201C';
  position: absolute;
  top: -0.5em;
  left: 50%;
  transform: translateX(-50%);
  font-size: 8rem;
  font-weight: 700;
  line-height: 1;
  background: linear-gradient(135deg, #ff2d78, #00f0ff);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  opacity: 0.15;
  pointer-events: none;
}

/* Gradient highlight on key phrases */
.testimonial-quote em {
  font-style: normal;
  background: linear-gradient(135deg, #ff2d78, #ffe600);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  font-weight: 500;
}

.testimonial-author {
  margin-top: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
}

.testimonial-avatar {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  object-fit: cover;
  border: 2px solid rgba(255, 255, 255, 0.1);
}

.testimonial-name {
  font-size: 0.95rem;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.9);
}

.testimonial-role {
  font-size: 0.8rem;
  color: rgba(255, 255, 255, 0.4);
  margin-top: 2px;
}
```

### HTML

```html
<section class="testimonial-section">
  <blockquote class="testimonial-quote">
    This completely <em>changed how we think</em> about tracking.
    Nothing else even comes close.
  </blockquote>
  <div class="testimonial-author">
    <img class="testimonial-avatar" src="avatar.jpg" alt="" />
    <div>
      <div class="testimonial-name">Sarah Chen</div>
      <div class="testimonial-role">CTO, Acme Labs</div>
    </div>
  </div>
</section>
```

### Variant: staggered multi-quote (floating, no containers)

```css
.quotes-float {
  display: flex;
  flex-direction: column;
  gap: 80px;
  max-width: 1000px;
  margin: 0 auto;
  padding: 120px 24px;
}

.quote-item:nth-child(odd) {
  text-align: left;
  padding-left: 10%;
}

.quote-item:nth-child(even) {
  text-align: right;
  padding-right: 10%;
}

.quote-text {
  font-size: clamp(1.3rem, 3vw, 2.2rem);
  font-weight: 300;
  color: rgba(255, 255, 255, 0.7);
  line-height: 1.5;
  transition: color 0.3s ease;
}

.quote-item:hover .quote-text {
  color: rgba(255, 255, 255, 0.95);
}

.quote-text strong {
  font-weight: 500;
  color: #00f0ff;
}

.quote-attribution {
  margin-top: 12px;
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.3);
}
```

---

## 9. Section Transition Polish

### Gradient mesh background

```css
.section-mesh {
  position: relative;
  overflow: hidden;
}

.section-mesh::before {
  content: '';
  position: absolute;
  inset: 0;
  background:
    radial-gradient(ellipse 80% 50% at 20% 40%, rgba(255, 45, 120, 0.08) 0%, transparent 60%),
    radial-gradient(ellipse 60% 80% at 80% 60%, rgba(0, 240, 255, 0.06) 0%, transparent 60%),
    radial-gradient(ellipse 50% 60% at 50% 20%, rgba(57, 255, 20, 0.04) 0%, transparent 50%);
  z-index: 0;
  pointer-events: none;
}
```

### Glow separator line between sections

```css
.glow-separator {
  width: 100%;
  height: 1px;
  border: none;
  background: linear-gradient(
    90deg,
    transparent 0%,
    rgba(0, 240, 255, 0.3) 20%,
    rgba(255, 45, 120, 0.5) 50%,
    rgba(0, 240, 255, 0.3) 80%,
    transparent 100%
  );
  position: relative;
}

.glow-separator::after {
  content: '';
  position: absolute;
  top: -20px;
  left: 0;
  right: 0;
  height: 40px;
  background: linear-gradient(
    90deg,
    transparent 0%,
    rgba(255, 45, 120, 0.06) 30%,
    rgba(255, 45, 120, 0.1) 50%,
    rgba(255, 45, 120, 0.06) 70%,
    transparent 100%
  );
  filter: blur(10px);
  pointer-events: none;
}
```

### Animated glow separator (light runs along the line)

```css
.glow-separator-animated {
  width: 100%;
  height: 1px;
  border: none;
  background: rgba(255, 255, 255, 0.06);
  position: relative;
  overflow: visible;
}

.glow-separator-animated::before {
  content: '';
  position: absolute;
  top: -1px;
  left: 0;
  width: 120px;
  height: 3px;
  background: linear-gradient(
    90deg,
    transparent,
    #00f0ff,
    transparent
  );
  border-radius: 2px;
  filter: blur(2px);
  animation: line-run 4s ease-in-out infinite;
}

@keyframes line-run {
  0% { left: -120px; }
  50% { left: calc(100% + 120px); }
  50.01% { left: -120px; opacity: 0; }
  55% { opacity: 1; }
  100% { left: -120px; }
}
```

### Subtle color shift between sections (scroll-aware)

```css
/* Section backgrounds that subtly shift the mesh color */
.section--pink {
  --mesh-accent: rgba(255, 45, 120, 0.06);
  --mesh-secondary: rgba(0, 240, 255, 0.04);
}

.section--cyan {
  --mesh-accent: rgba(0, 240, 255, 0.06);
  --mesh-secondary: rgba(57, 255, 20, 0.04);
}

.section--green {
  --mesh-accent: rgba(57, 255, 20, 0.06);
  --mesh-secondary: rgba(255, 230, 0, 0.04);
}

.section--pink::before,
.section--cyan::before,
.section--green::before {
  content: '';
  position: absolute;
  inset: 0;
  background:
    radial-gradient(ellipse 60% 40% at 30% 50%, var(--mesh-accent) 0%, transparent 70%),
    radial-gradient(ellipse 50% 60% at 70% 40%, var(--mesh-secondary) 0%, transparent 60%);
  pointer-events: none;
  z-index: 0;
}
```

### Noise texture overlay (adds tactile depth)

```css
.noise-overlay::after {
  content: '';
  position: absolute;
  inset: 0;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.04'/%3E%3C/svg%3E");
  background-repeat: repeat;
  background-size: 256px 256px;
  pointer-events: none;
  z-index: 1;
  mix-blend-mode: overlay;
}
```

---

## 10. Button Shimmer Effect (Apple Light Sweep)

The classic periodic light sweep that crosses a button surface.

```css
.apple-shimmer {
  position: relative;
  padding: 14px 32px;
  font-size: 1rem;
  font-weight: 600;
  color: #fff;
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 12px;
  overflow: hidden;
  cursor: pointer;
  backdrop-filter: blur(12px);
}

.apple-shimmer::before {
  content: '';
  position: absolute;
  top: 0;
  left: -150%;
  width: 80%;
  height: 100%;
  background: linear-gradient(
    105deg,
    transparent 20%,
    rgba(255, 255, 255, 0.03) 35%,
    rgba(255, 255, 255, 0.12) 48%,
    rgba(255, 255, 255, 0.12) 52%,
    rgba(255, 255, 255, 0.03) 65%,
    transparent 80%
  );
  animation: apple-sweep 5s ease-in-out infinite;
}

@keyframes apple-sweep {
  0% { left: -150%; }
  15% { left: 150%; }
  100% { left: 150%; }
}
```

### Variant: colored shimmer (neon accent)

```css
.neon-shimmer::before {
  background: linear-gradient(
    105deg,
    transparent 20%,
    rgba(0, 240, 255, 0.0) 35%,
    rgba(0, 240, 255, 0.08) 48%,
    rgba(0, 240, 255, 0.08) 52%,
    rgba(0, 240, 255, 0.0) 65%,
    transparent 80%
  );
}
```

### Variant: hover-only shimmer (not periodic)

```css
.hover-shimmer {
  position: relative;
  overflow: hidden;
}

.hover-shimmer::before {
  content: '';
  position: absolute;
  top: 0;
  left: -150%;
  width: 80%;
  height: 100%;
  background: linear-gradient(
    105deg,
    transparent 20%,
    rgba(255, 255, 255, 0.12) 50%,
    transparent 80%
  );
  transition: none;
}

.hover-shimmer:hover::before {
  animation: hover-sweep 0.6s ease forwards;
}

@keyframes hover-sweep {
  0% { left: -150%; }
  100% { left: 150%; }
}
```

---

## Bonus: Global Setup and Utility Classes

### Base dark theme

```css
:root {
  --bg: #0a0a0f;
  --pink: #ff2d78;
  --green: #39ff14;
  --yellow: #ffe600;
  --cyan: #00f0ff;
  --text: rgba(255, 255, 255, 0.85);
  --text-muted: rgba(255, 255, 255, 0.45);
  --spring-enter: cubic-bezier(0.34, 1.56, 0.64, 1);
  --spring-bounce: cubic-bezier(0.68, -0.55, 0.265, 1.55);
  --spring-snap: cubic-bezier(0.22, 1.5, 0.36, 1);
}

body {
  background: var(--bg);
  color: var(--text);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
```

### Reduced motion respect

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

### Performance: force GPU compositing

```css
.gpu {
  will-change: transform;
  transform: translateZ(0);
}
```
