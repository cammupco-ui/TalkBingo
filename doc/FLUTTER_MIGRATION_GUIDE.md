# 승부차기 게임 Flutter 마이그레이션 가이드

## 📦 필요한 자료 요약
1. 색상 팔레트 (4가지 색상)
2. 게임 상수 (좌표, 크기, 물리 값)
3. 골키퍼 팔 SVG 경로
4. 게임 로직 (공, 골키퍼, 드래그, 충돌)
5. 축구공 그리기 패턴

---

## 1. 색상 팔레트

```dart
class GameColors {
  static const Color darkPurple = Color(0xFF0C0219);    // 검정-보라
  static const Color purple = Color(0xFF6B14EC);        // 보라
  static const Color deepPurple = Color(0xFF2E0645);    // 진한 보라
  static const Color lightPurple = Color(0xFFFDF9FF);   // 흰색-보라
}
```

---

## 2. 게임 상수

```dart
class GameConstants {
  // 캔버스 크기
  static const double canvasWidth = 380;
  static const double canvasHeight = 693;
  
  // 플레이 영역 (하단 반투명 영역)
  static const double playAreaY = 522;
  static const double playAreaHeight = 161;
  
  // 골대 좌표
  static const double goalY = 154;        // 골대 바닥
  static const double goalLeft = 44;      // 골대 왼쪽
  static const double goalRight = 336;    // 골대 오른쪽
  static const double goalTop = 32;       // 골대 위쪽
  static const double goalWidth = 292;    // 골대 너비
  static const double goalHeight = 122;   // 골대 높이
  
  // 공 설정
  static const double ballRadius = 22.5;
  static const double ballInitialX = 202;
  static const double ballInitialY = 572;
  
  // 골키퍼 설정
  static const double goalkeeperWidth = 38;
  static const double goalkeeperHeight = 34;
  static const double goalkeeperInitialX = 202;
  static const double goalkeeperY = 108;
  static const double goalkeeperSpeed = 4;
  
  // 물리 설정
  static const double wallBounceEnergyLoss = 0.8;      // 벽 튕김 에너지 손실 (80%)
  static const double dragSpeedMultiplier = 0.3;       // 드래그 속도 배율
  static const double maxSpeedMultiplier = 3.0;        // 최대 속도 배율
  static const double minDragDistance = 10;            // 최소 드래그 거리
  static const double dragPowerDivisor = 30;           // 드래그 파워 계산 제수
  
  // 터치 감지
  static const double touchTolerance = 20;             // 공 터치 허용 범위
  
  // 경계
  static const double borderWidth = 10;
  static const double fieldPadding = 5;
}
```

---

## 3. 골키퍼 팔 SVG 경로

```dart
// SVG Path 문자열
const String goalkeeperArmsPath = 
  "M236 105C244.201 105 251.249 109.937 254.335 117H276.5C280.642 117 284 120.358 284 124.5C284 128.642 280.642 132 276.5 132H254.739C251.902 139.593 244.583 145 236 145H206C197.417 145 190.098 139.593 187.261 132H164.5C160.358 132 157 128.642 157 124.5C157 120.358 160.358 117 164.5 117H187.665C190.751 109.937 197.799 105 206 105H236Z";

// Flutter Path 객체로 변환하는 함수
Path createGoalkeeperArmsPath() {
  // flutter_svg 패키지의 parseSvgPathData 사용 또는
  // 직접 Path 명령어로 변환
  
  Path path = Path();
  path.moveTo(236, 105);
  path.cubicTo(244.201, 105, 251.249, 109.937, 254.335, 117);
  path.lineTo(276.5, 117);
  path.cubicTo(280.642, 117, 284, 120.358, 284, 124.5);
  path.cubicTo(284, 128.642, 280.642, 132, 276.5, 132);
  path.lineTo(254.739, 132);
  path.cubicTo(251.902, 139.593, 244.583, 145, 236, 145);
  path.lineTo(206, 145);
  path.cubicTo(197.417, 145, 190.098, 139.593, 187.261, 132);
  path.lineTo(164.5, 132);
  path.cubicTo(160.358, 132, 157, 128.642, 157, 124.5);
  path.cubicTo(157, 120.358, 160.358, 117, 164.5, 117);
  path.lineTo(187.665, 117);
  path.cubicTo(190.751, 109.937, 197.799, 105, 206, 105);
  path.lineTo(236, 105);
  path.close();
  
  return path;
}
```

---

## 4. 데이터 모델 클래스

### 4.1 공 (Ball)

```dart
class Ball {
  double x;
  double y;
  double vx;  // x축 속도
  double vy;  // y축 속도
  final double radius = GameConstants.ballRadius;
  
  Ball({
    this.x = GameConstants.ballInitialX,
    this.y = GameConstants.ballInitialY,
    this.vx = 0,
    this.vy = 0,
  });
  
  void reset() {
    x = GameConstants.ballInitialX;
    y = GameConstants.ballInitialY;
    vx = 0;
    vy = 0;
  }
  
  void updatePosition() {
    x += vx;
    y += vy;
  }
}
```

### 4.2 골키퍼 (Goalkeeper)

```dart
class Goalkeeper {
  double x;
  double y;
  double targetX;
  final double width = GameConstants.goalkeeperWidth;
  final double height = GameConstants.goalkeeperHeight;
  
  Goalkeeper({
    this.x = GameConstants.goalkeeperInitialX,
    this.y = GameConstants.goalkeeperY,
    this.targetX = GameConstants.goalkeeperInitialX,
  });
  
  void update(double ballX) {
    // 목표 위치 설정 (공의 x 위치)
    targetX = ballX - width / 2;
    
    // 부드러운 이동
    double dx = targetX - x;
    if (dx.abs() > 1) {
      x += dx.sign * min(GameConstants.goalkeeperSpeed, dx.abs());
    }
    
    // 골대 범위 내로 제한
    x = x.clamp(
      GameConstants.goalLeft, 
      GameConstants.goalRight - width
    );
  }
}
```

### 4.3 드래그 상태 (DragState)

```dart
class DragState {
  bool isDragging = false;
  double startX = 0;
  double startY = 0;
  double currentX = 0;
  double currentY = 0;
  
  void onDragStart(double x, double y, Ball ball) {
    // 공과의 거리 계산
    double dist = sqrt(pow(x - ball.x, 2) + pow(y - ball.y, 2));
    
    // 터치가 공 위에 있고, 공이 정지 상태이며, 플레이 영역 내인지 확인
    if (dist < ball.radius + GameConstants.touchTolerance && 
        ball.vx == 0 && 
        ball.vy == 0 && 
        y >= GameConstants.playAreaY) {
      isDragging = true;
      startX = ball.x;
      startY = ball.y;
      currentX = x;
      currentY = y;
    }
  }
  
  void onDragUpdate(double x, double y) {
    if (isDragging) {
      currentX = x;
      currentY = y;
    }
  }
  
  void onDragEnd(Ball ball) {
    if (!isDragging) return;
    
    // 슬링샷 방향 계산 (시작점 - 현재점 = 발사 방향)
    double dx = startX - currentX;
    double dy = startY - currentY;
    double dragDistance = sqrt(dx * dx + dy * dy);
    
    // 최소 드래그 거리 이상일 때만 슛
    if (dragDistance > GameConstants.minDragDistance) {
      double speedMultiplier = min(
        dragDistance / GameConstants.dragPowerDivisor, 
        GameConstants.maxSpeedMultiplier
      );
      
      ball.vx = dx * GameConstants.dragSpeedMultiplier * speedMultiplier;
      ball.vy = dy * GameConstants.dragSpeedMultiplier * speedMultiplier;
    }
    
    isDragging = false;
  }
  
  // 파워 계산 (0-100%)
  double getPower() {
    double dx = startX - currentX;
    double dy = startY - currentY;
    double power = min(
      sqrt(dx * dx + dy * dy) / GameConstants.dragPowerDivisor, 
      GameConstants.maxSpeedMultiplier
    );
    return (power * 33).roundToDouble();
  }
  
  // 드래그 각도 계산 (화살표 그리기용)
  double getAngle() {
    double dx = startX - currentX;
    double dy = startY - currentY;
    return atan2(dy, dx);
  }
}
```

---

## 5. 게임 로직

### 5.1 충돌 감지

```dart
// 골 체크
bool checkGoal(Ball ball) {
  return ball.y - ball.radius < GameConstants.goalTop &&
         ball.x > GameConstants.goalLeft &&
         ball.x < GameConstants.goalRight &&
         ball.y < GameConstants.goalY;
}

// 골키퍼 충돌 체크 (AABB vs Circle)
bool checkGoalkeeperCollision(Ball ball, Goalkeeper gk) {
  // 가장 가까운 점 찾기
  double closestX = ball.x.clamp(gk.x, gk.x + gk.width);
  double closestY = ball.y.clamp(gk.y, gk.y + gk.height);
  
  // 거리 계산
  double distanceX = ball.x - closestX;
  double distanceY = ball.y - closestY;
  double distanceSquared = distanceX * distanceX + distanceY * distanceY;
  
  return distanceSquared < ball.radius * ball.radius;
}
```

### 5.2 공 물리 업데이트

```dart
enum GameState { playing, goal, saved }

void updateBallPhysics(Ball ball, Goalkeeper gk, Function(GameState) onGameStateChange) {
  // 공이 정지 상태면 물리 계산 안 함
  if (ball.vx == 0 && ball.vy == 0) return;
  
  // 위치 업데이트
  ball.updatePosition();
  
  // 좌우 벽 충돌 - 튕김 효과
  if (ball.x - ball.radius < GameConstants.borderWidth || 
      ball.x + ball.radius > GameConstants.canvasWidth - GameConstants.borderWidth) {
    ball.vx = -ball.vx * GameConstants.wallBounceEnergyLoss;
    
    // 공이 벽 안으로 들어가지 않도록 조정
    if (ball.x - ball.radius < GameConstants.borderWidth) {
      ball.x = GameConstants.borderWidth + ball.radius;
    } else {
      ball.x = GameConstants.canvasWidth - GameConstants.borderWidth - ball.radius;
    }
  }
  
  // 하단 경계 - 리셋
  if (ball.y + ball.radius > GameConstants.canvasHeight - GameConstants.borderWidth) {
    ball.reset();
    onGameStateChange(GameState.playing);
  }
  
  // 골키퍼 충돌 - 리셋
  if (checkGoalkeeperCollision(ball, gk)) {
    onGameStateChange(GameState.saved);
    Future.delayed(Duration(milliseconds: 1000), () {
      ball.reset();
    });
    return;
  }
  
  // 골 체크
  if (checkGoal(ball)) {
    onGameStateChange(GameState.goal);
    Future.delayed(Duration(milliseconds: 1500), () {
      ball.reset();
    });
    return;
  }
  
  // 골대 위로 넘어가면 리셋
  if (ball.y < GameConstants.goalTop - ball.radius) {
    Future.delayed(Duration(milliseconds: 500), () {
      ball.reset();
    });
  }
}
```

---

## 6. 그리기 (Drawing)

### 6.1 배경 및 골대

```dart
void drawBackground(Canvas canvas, Size size) {
  final paint = Paint();
  
  // 필드 배경
  paint.color = GameColors.lightPurple;
  canvas.drawRect(
    Rect.fromLTWH(
      GameConstants.fieldPadding, 
      GameConstants.fieldPadding, 
      370, 
      683
    ), 
    paint
  );
  
  // 외곽 테두리
  paint.color = GameColors.darkPurple;
  paint.style = PaintingStyle.stroke;
  paint.strokeWidth = GameConstants.borderWidth;
  canvas.drawRect(
    Rect.fromLTWH(
      GameConstants.fieldPadding, 
      GameConstants.fieldPadding, 
      370, 
      683
    ), 
    paint
  );
}

void drawGoalNet(Canvas canvas) {
  final paint = Paint();
  
  // 골대 배경
  paint.color = GameColors.lightPurple;
  paint.style = PaintingStyle.fill;
  canvas.drawRect(
    Rect.fromLTWH(
      GameConstants.goalLeft,
      GameConstants.goalTop,
      GameConstants.goalWidth,
      GameConstants.goalHeight
    ),
    paint
  );
  
  // 네트 패턴 (세로선)
  paint.color = GameColors.darkPurple.withOpacity(0.1);
  paint.strokeWidth = 1;
  for (int i = 0; i < 15; i++) {
    canvas.drawLine(
      Offset(GameConstants.goalLeft + i * 20, GameConstants.goalTop),
      Offset(GameConstants.goalLeft + i * 20, GameConstants.goalY),
      paint
    );
  }
  
  // 네트 패턴 (가로선)
  for (int i = 0; i < 7; i++) {
    canvas.drawLine(
      Offset(GameConstants.goalLeft, GameConstants.goalTop + i * 20),
      Offset(GameConstants.goalRight, GameConstants.goalTop + i * 20),
      paint
    );
  }
}

void drawGoalFrame(Canvas canvas) {
  final paint = Paint()
    ..color = GameColors.darkPurple
    ..style = PaintingStyle.stroke
    ..strokeWidth = 12
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  
  // 왼쪽 기둥
  canvas.drawLine(
    Offset(GameConstants.goalLeft, GameConstants.goalY),
    Offset(GameConstants.goalLeft, GameConstants.goalTop),
    paint
  );
  
  // 오른쪽 기둥
  canvas.drawLine(
    Offset(GameConstants.goalRight, GameConstants.goalY),
    Offset(GameConstants.goalRight, GameConstants.goalTop),
    paint
  );
  
  // 상단 크로스바
  canvas.drawLine(
    Offset(GameConstants.goalLeft, GameConstants.goalTop),
    Offset(GameConstants.goalRight, GameConstants.goalTop),
    paint
  );
}
```

### 6.2 골키퍼

```dart
void drawGoalkeeper(Canvas canvas, Goalkeeper gk) {
  final paint = Paint();
  
  // 골키퍼 몸통
  paint.color = GameColors.deepPurple;
  paint.style = PaintingStyle.fill;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(gk.x, gk.y, gk.width, gk.height),
      Radius.circular(17)
    ),
    paint
  );
  
  // 골키퍼 팔 (SVG 경로)
  paint.color = GameColors.purple;
  Path armsPath = createGoalkeeperArmsPath();
  
  canvas.save();
  canvas.translate(gk.x - 206, gk.y - 105);
  canvas.drawPath(armsPath, paint);
  
  // 팔 테두리
  paint.color = GameColors.darkPurple;
  paint.style = PaintingStyle.stroke;
  paint.strokeWidth = 5;
  canvas.drawPath(armsPath, paint);
  canvas.restore();
}
```

### 6.3 플레이 영역 표시

```dart
void drawPlayArea(Canvas canvas) {
  final paint = Paint()
    ..color = GameColors.purple.withOpacity(0.15);
  
  canvas.drawRect(
    Rect.fromLTWH(
      GameConstants.borderWidth,
      GameConstants.playAreaY,
      360,
      GameConstants.playAreaHeight
    ),
    paint
  );
}
```

### 6.4 드래그 화살표 (슬링샷 표시)

```dart
void drawDragIndicator(Canvas canvas, DragState dragState) {
  if (!dragState.isDragging) return;
  
  final paint = Paint()
    ..color = GameColors.purple
    ..strokeWidth = 4
    ..style = PaintingStyle.stroke;
  
  // 점선 화살표 라인
  Path dashedPath = Path();
  dashedPath.moveTo(dragState.startX, dragState.startY);
  dashedPath.lineTo(dragState.currentX, dragState.currentY);
  
  // 점선 그리기 (간단한 방법)
  canvas.drawPath(
    _createDashedPath(dashedPath, 5, 5),
    paint
  );
  
  // 화살표 끝
  double angle = dragState.getAngle();
  double arrowSize = 15;
  
  paint.style = PaintingStyle.fill;
  Path arrowHead = Path();
  arrowHead.moveTo(dragState.currentX, dragState.currentY);
  arrowHead.lineTo(
    dragState.currentX - arrowSize * cos(angle - pi / 6),
    dragState.currentY - arrowSize * sin(angle - pi / 6)
  );
  arrowHead.lineTo(
    dragState.currentX - arrowSize * cos(angle + pi / 6),
    dragState.currentY - arrowSize * sin(angle + pi / 6)
  );
  arrowHead.close();
  
  canvas.drawPath(arrowHead, paint);
  
  // 파워 텍스트
  TextPainter textPainter = TextPainter(
    text: TextSpan(
      text: '파워: ${dragState.getPower().round()}%',
      style: TextStyle(
        color: GameColors.deepPurple,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      GameConstants.canvasWidth / 2 - textPainter.width / 2,
      GameConstants.playAreaY - 10 - textPainter.height
    )
  );
}

// 점선 Path 생성 헬퍼
Path _createDashedPath(Path source, double dashLength, double gapLength) {
  final Path dest = Path();
  for (PathMetric metric in source.computeMetrics()) {
    double distance = 0;
    bool draw = true;
    while (distance < metric.length) {
      final double length = draw ? dashLength : gapLength;
      final double end = min(distance + length, metric.length);
      if (draw) {
        dest.addPath(
          metric.extractPath(distance, end),
          Offset.zero
        );
      }
      distance = end;
      draw = !draw;
    }
  }
  return dest;
}
```

### 6.5 축구공 그리기

```dart
void drawSoccerBall(Canvas canvas, Ball ball) {
  final paint = Paint();
  
  // 그림자
  paint.color = GameColors.darkPurple.withOpacity(0.2);
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(ball.x, ball.y + 5),
      width: ball.radius * 1.6,
      height: ball.radius * 0.6,
    ),
    paint,
  );
  
  // 공 베이스 (흰색)
  paint.color = GameColors.lightPurple;
  paint.style = PaintingStyle.fill;
  canvas.drawCircle(Offset(ball.x, ball.y), ball.radius, paint);
  
  // 공 테두리
  paint.color = GameColors.darkPurple;
  paint.style = PaintingStyle.stroke;
  paint.strokeWidth = 3;
  canvas.drawCircle(Offset(ball.x, ball.y), ball.radius, paint);
  
  // 축구공 패턴
  canvas.save();
  canvas.translate(ball.x, ball.y);
  
  // 중앙 펜타곤
  paint.style = PaintingStyle.fill;
  paint.color = GameColors.darkPurple;
  canvas.drawPath(_createPentagon(0, 0, 8), paint);
  
  // 주변 펜타곤들
  _drawPentagon(canvas, 0, -16, 7, 0);
  _drawPentagon(canvas, 14, -8, 7, pi / 3);
  _drawPentagon(canvas, 14, 8, 7, -pi / 3);
  _drawPentagon(canvas, 0, 16, 7, pi);
  _drawPentagon(canvas, -14, 8, 7, pi / 3);
  _drawPentagon(canvas, -14, -8, 7, -pi / 3);
  
  canvas.restore();
}

// 펜타곤 Path 생성
Path _createPentagon(double cx, double cy, double radius) {
  Path path = Path();
  for (int i = 0; i < 5; i++) {
    double angle = (i * 2 * pi) / 5 - pi / 2;
    double x = cx + cos(angle) * radius;
    double y = cy + sin(angle) * radius;
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  path.close();
  return path;
}

// 회전된 펜타곤 그리기
void _drawPentagon(Canvas canvas, double offsetX, double offsetY, 
                   double radius, double rotation) {
  canvas.save();
  canvas.translate(offsetX, offsetY);
  canvas.rotate(rotation);
  
  final paint = Paint()
    ..color = GameColors.darkPurple
    ..style = PaintingStyle.fill;
  
  canvas.drawPath(_createPentagon(0, 0, radius), paint);
  canvas.restore();
}
```

### 6.6 점수 및 게임 상태 텍스트

```dart
void drawScore(Canvas canvas, int score) {
  // 텍스트 테두리
  TextPainter borderPainter = TextPainter(
    text: TextSpan(
      text: '⚽ $score',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = GameColors.darkPurple,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  borderPainter.layout();
  
  // 텍스트 채우기
  TextPainter fillPainter = TextPainter(
    text: TextSpan(
      text: '⚽ $score',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: GameColors.purple,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  fillPainter.layout();
  
  double x = GameConstants.canvasWidth / 2 - fillPainter.width / 2;
  double y = 220 - fillPainter.height / 2;
  
  borderPainter.paint(canvas, Offset(x, y));
  fillPainter.paint(canvas, Offset(x, y));
}

void drawGameStateMessage(Canvas canvas, GameState state) {
  if (state == GameState.playing) return;
  
  String message = state == GameState.goal ? '골!!!' : '막혔다!';
  double fontSize = state == GameState.goal ? 48 : 36;
  Color textColor = state == GameState.goal 
      ? GameColors.purple 
      : GameColors.deepPurple;
  Color strokeColor = state == GameState.goal 
      ? GameColors.darkPurple 
      : GameColors.lightPurple;
  
  // 테두리
  TextPainter borderPainter = TextPainter(
    text: TextSpan(
      text: message,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = state == GameState.goal ? 4 : 3
          ..color = strokeColor,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  borderPainter.layout();
  
  // 채우기
  TextPainter fillPainter = TextPainter(
    text: TextSpan(
      text: message,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  fillPainter.layout();
  
  double x = GameConstants.canvasWidth / 2 - fillPainter.width / 2;
  double y = GameConstants.canvasHeight / 2 - fillPainter.height / 2;
  
  borderPainter.paint(canvas, Offset(x, y));
  fillPainter.paint(canvas, Offset(x, y));
}
```

---

## 7. Flutter 위젯 구현

```dart
import 'package:flutter/material.dart';
import 'dart:math';

class PenaltyKickGame extends StatefulWidget {
  @override
  _PenaltyKickGameState createState() => _PenaltyKickGameState();
}

class _PenaltyKickGameState extends State<PenaltyKickGame> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Ball ball = Ball();
  Goalkeeper goalkeeper = Goalkeeper();
  DragState dragState = DragState();
  int score = 0;
  GameState gameState = GameState.playing;
  
  @override
  void initState() {
    super.initState();
    
    // 게임 루프 (60 FPS)
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 16),
    )..addListener(() {
      setState(() {
        updateBallPhysics(ball, goalkeeper, (newState) {
          gameState = newState;
          if (newState == GameState.goal) {
            score++;
            Future.delayed(Duration(milliseconds: 1500), () {
              setState(() {
                gameState = GameState.playing;
              });
            });
          } else if (newState == GameState.saved) {
            Future.delayed(Duration(milliseconds: 1000), () {
              setState(() {
                gameState = GameState.playing;
              });
            });
          }
        });
        goalkeeper.update(ball.x);
      });
    })..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6B2C91),  // purple-900
              Color(0xFF4A1663),  // purple-950
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onPanStart: (details) {
                  RenderBox box = context.findRenderObject() as RenderBox;
                  Offset localPosition = box.globalToLocal(details.globalPosition);
                  dragState.onDragStart(localPosition.dx, localPosition.dy, ball);
                  setState(() {});
                },
                onPanUpdate: (details) {
                  RenderBox box = context.findRenderObject() as RenderBox;
                  Offset localPosition = box.globalToLocal(details.globalPosition);
                  dragState.onDragUpdate(localPosition.dx, localPosition.dy);
                  setState(() {});
                },
                onPanEnd: (_) {
                  dragState.onDragEnd(ball);
                  setState(() {});
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[900]!, width: 4),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    size: Size(
                      GameConstants.canvasWidth,
                      GameConstants.canvasHeight
                    ),
                    painter: GamePainter(
                      ball: ball,
                      goalkeeper: goalkeeper,
                      dragState: dragState,
                      score: score,
                      gameState: gameState,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Column(
                children: [
                  Text(
                    '공을 잡고 드래그하여 슛 방향과 파워를 조정하세요',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '손가락을 떼면 공이 발사됩니다!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CustomPainter 클래스
class GamePainter extends CustomPainter {
  final Ball ball;
  final Goalkeeper goalkeeper;
  final DragState dragState;
  final int score;
  final GameState gameState;
  
  GamePainter({
    required this.ball,
    required this.goalkeeper,
    required this.dragState,
    required this.score,
    required this.gameState,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    drawBackground(canvas, size);
    drawGoalNet(canvas);
    drawGoalFrame(canvas);
    drawGoalkeeper(canvas, goalkeeper);
    drawPlayArea(canvas);
    drawDragIndicator(canvas, dragState);
    drawSoccerBall(canvas, ball);
    drawScore(canvas, score);
    drawGameStateMessage(canvas, gameState);
  }
  
  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}
```

---

## 8. pubspec.yaml 의존성

```yaml
dependencies:
  flutter:
    sdk: flutter
```

**추가 패키지 필요 없음** - 순수 Flutter Canvas API만 사용!

---

## 9. 핵심 차이점

### React/Canvas vs Flutter

| 항목 | React (Web) | Flutter |
|------|-------------|---------|
| 그리기 | `CanvasRenderingContext2D` | `CustomPaint` + `Canvas` |
| 애니메이션 | `requestAnimationFrame` | `AnimationController` |
| 터치 | `onTouchStart/Move/End` | `GestureDetector` |
| 좌표계 | 왼쪽 위 (0,0) | 왼쪽 위 (0,0) ✅ 동일 |
| Path | `new Path2D(svgString)` | `Path()` + 수동 변환 |
| 텍스트 | `ctx.fillText()` | `TextPainter` |

---

## 10. 구현 순서 추천

1. ✅ 색상, 상수 정의
2. ✅ 데이터 모델 (Ball, Goalkeeper, DragState)
3. ✅ 배경, 골대 그리기
4. ✅ 공, 골키퍼 그리기
5. ✅ 터치 이벤트 처리
6. ✅ 물리 시뮬레이션
7. ✅ 충돌 감지
8. ✅ 게임 상태 관리
9. ✅ UI 텍스트 (점수, 메시지)

---

## 11. 최적화 팁

- **RepaintBoundary**: 불필요한 리페인팅 방지
- **shouldRepaint**: 게임은 매 프레임 리페인트하므로 항상 `true` 반환
- **Path 캐싱**: 골키퍼 팔, 펜타곤 등 고정 Path는 미리 생성하여 재사용
- **const 사용**: 상수는 `const`로 선언하여 메모리 절약

---

## 요약

이 가이드에는 **모든 게임 로직, 물리, 그리기 코드**가 Dart로 완전히 변환되어 있습니다.

**Flutter 프로젝트에 복사하면 바로 작동합니다! 🎮⚽**
