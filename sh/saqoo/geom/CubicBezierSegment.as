package sh.saqoo.geom {

	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;

	/**
	 * @author Saqoosha
	 */
	public dynamic class CubicBezierSegment extends Proxy implements IParametricCurve, IExternalizable {
		
		
		private static var __drawFunc:Function = __draw3;
		
		
		public static function draw(graphics:Graphics, p0:Point, p1:Point, p2:Point, p3:Point, moveToStart:Boolean = true):void {
			if (moveToStart) graphics.moveTo(p0.x, p0.y);
//			__drawFunc(graphics, p0, p1, p2, p3);
			__draw3(graphics, p0, p1, p2, p3);
		}
		
		
		public static function drawSegments(graphics:Graphics, segments:Vector.<CubicBezierSegment>):void {
			graphics.moveTo(segments[0].p0.x, segments[0].p0.y);
			var n:int = segments.length;
			for (var i:int = 0; i < n; i++) {
				segments[i].draw(graphics, false);
			}
		}
		
		
		public static function buildLineSegment(p0:Point, p1:Point):CubicBezierSegment {
			return new CubicBezierSegment(p0, Point.interpolate(p0, p1, 0.66), Point.interpolate(p0, p1, 0.33), p1);
		}

		//
		
		private var _p0:Point;
		private var _p1:Point;
		private var _p2:Point;
		private var _p3:Point;
		
		private var _points:Vector.<Point>;

		//
		
		public function get p0():Point { return _p0; }
		public function set p0(value:Point):void {
			_p0.x = value.x;
			_p0.y = value.y;
		}
		
		public function get p1():Point { return _p1; }
		public function set p1(value:Point):void {
			_p1.x = value.x;
			_p1.y = value.y;
		}
		
		public function get p2():Point { return _p2; }
		public function set p2(value:Point):void {
			_p2.x = value.x;
			_p2.y = value.y;
		}
		
		public function get p3():Point { return _p3; }
		public function set p3(value:Point):void {
			_p3.x = value.x;
			_p3.y = value.y;
		}

		//
		
		public function CubicBezierSegment(p0:Point = null, p1:Point = null, p2:Point = null, p3:Point = null) {
			_p0 = p0 || new Point();
			_p1 = p1 || new Point();
			_p2 = p2 || new Point();
			_p3 = p3 || new Point();
			_points = Vector.<Point>([_p0, _p1, _p2, _p3]);
		}
		
		
		public function getLength(n:uint = 4):Number {
			n = Math.pow(2, n);
			var p0:Point = getPointAt(0);
			var p1:Point = new Point();
			var len:Number = 0;
			for (var i:int = 1; i <= n; i++) {
				getPointAt(i / n, p1);
				len += Point.distance(p0, p1);
				p0.x = p1.x;
				p0.y = p1.y;
			}
			return len;
		}
		
		
		public function getPointAt(t:Number, out:Point = null):Point {
			out ||= new Point();
			var a:Number = 1 - t;
			var b:Number = a * a;
			var c:Number = t * t;
			var c0:Number = a * b;
			var c1:Number = 3 * b * t;
			var c2:Number = 3 * a * c;
			var c3:Number = t * c;
			out.x = _p0.x * c0 + _p1.x * c1 + _p2.x * c2 + _p3.x * c3;			out.y = _p0.y * c0 + _p1.y * c1 + _p2.y * c2 + _p3.y * c3;
			return out;
		}
		
		
		public function getTangentAt(t:Number, out:Point = null):Point {
			out ||= new Point();
			var t1:Number = t - 1;
			var t12:Number = t1 * t1;
			var t2:Number = t * t;
			var t3:Number = 2 * t1 * t;
			var a:Number = -3 * t12;
			var b:Number = 3 * (t3 + t12);
			var c:Number = -3 * (t2 + t3);
			var d:Number = 3 * t2;
			out.x = _p0.x * a + _p1.x * b + _p2.x * c + _p3.x * d;			out.y = _p0.y * a + _p1.y * b + _p2.y * c + _p3.y * d;
			return out;
		}
		
		
		public function getParameterAtLength(length:Number):Number {
			if (length < 0) return 0;
			var total:Number = getLength();
			if (total <= length) return 1;
			var n:int = total / 5;
			var tr:Array = [0];
			var lr:Array = [0];
			var p0:Point = getPointAt(0);
			var p1:Point = new Point();
			for (var i:int = 1; i <= n; i++) {
				var t:Number = i / n;
				tr.push(t);
				getPointAt(t, p1);
				lr.push(lr[i - 1] + Point.distance(p0, p1));;
				p0.x = p1.x;
				p0.y = p1.y;
			}
			var r:int, m:int, l:int;
			r = 0;
			l = n - 1;
			m = (r + l) / 2;
			while (l - r > 1) {
				if (lr[m] < length) {
					r = m;
				} else {
					l = m;
				}
				m = (r + l) / 2;
			}
			t = (length - lr[r]) / (lr[l] - lr[r]) * (tr[l] - tr[r]) + tr[r];
			return t;
		}
		
		
		/**
		 * @see http://d.hatena.ne.jp/nishiohirokazu/20090616/1245104751
		 */
		public function getBounds():Rectangle {
			var a:Number, b:Number, c:Number, d:Number;
			var t:Number, p:Point = new Point();
			var v:Array;
			var minX:Number, maxX:Number, minY:Number, maxY:Number;
			
			v = [_p0.x, _p3.x];
			b = 6 * _p0.x - 12 * _p1.x + 6 * _p2.x;
			a = -3 * _p0.x + 9 * _p1.x - 9 * _p2.x + 3 * _p3.x;
			c = 3 * _p1.x - 3 * _p0.x;
			if (a == 0) {
				if (b != 0) {
					t = -c / b;
					if (0 < t && t < 1) v.push(getPointAt(t, p).x);
				}
			} else {
				d = b * b - 4 * c * a;
				if (d >= 0) {
					a *= 2;
					d = Math.sqrt(d);
					t = (-b + d) / a;
					if (0 < t && t < 1) v.push(getPointAt(t, p).x);
					t = (-b - d) / a;
					if (0 < t && t < 1) v.push(getPointAt(t, p).x);
				}
			}
			minX = Math.min.apply(null, v);
			maxX = Math.max.apply(null, v);
			
			v = [_p0.y, _p3.y];
			b = 6 * _p0.y - 12 * _p1.y + 6 * _p2.y;
			a = -3 * _p0.y + 9 * _p1.y - 9 * _p2.y + 3 * _p3.y;
			c = 3 * _p1.y - 3 * _p0.y;
			if (a == 0) {
				if (b != 0) {
					t = -c / b;
					if (0 < t && t < 1) v.push(getPointAt(t, p).y);
				}
			} else {
				d = b * b - 4 * c * a;
				if (d >= 0) {
					a *= 2;
					d = Math.sqrt(d);
					t = (-b + d) / a;
					if (0 < t && t < 1) v.push(getPointAt(t, p).y);
					t = (-b - d) / a;
					if (0 < t && t < 1) v.push(getPointAt(t, p).y);
				}
			}
			minY = Math.min.apply(null, v);
			maxY = Math.max.apply(null, v);
			
			return new Rectangle(minX, minY, Math.max(1e-5, maxX - minX), Math.max(1e-5, maxY - minY));
		}
		
		
		public function draw(graphics:Graphics, moveToStart:Boolean = true):void {
			if (moveToStart) graphics.moveTo(_p0.x, _p0.y);
			__drawFunc.call(null, graphics, _p0, _p1, _p2, _p3);
		}
		
		
		public function drawDebugInfo(graphics:Graphics):void {
			graphics.lineStyle(0, 0x0, 0.2);
			graphics.moveTo(_p0.x, _p0.y);
			graphics.lineTo(_p1.x, _p1.y);
			graphics.moveTo(_p2.x, _p2.y);
			graphics.lineTo(_p3.x, _p3.y);
			graphics.lineStyle();
			graphics.beginFill(0xff0000);
			graphics.drawCircle(_p0.x, _p0.y, 3);			graphics.drawCircle(_p3.x, _p3.y, 3);
			graphics.endFill();
			graphics.beginFill(0x0000ff);
			graphics.drawCircle(_p1.x, _p1.y, 3);
			graphics.drawCircle(_p2.x, _p2.y, 3);
			graphics.endFill();
		}
		
		
		public function split(t:Number = 0.5):Vector.<CubicBezierSegment> {
			t = 1 - t;
			
			var p01:Point = Point.interpolate(_p0, _p1, t);
			var p11:Point = Point.interpolate(_p1, _p2, t);
			var p21:Point = Point.interpolate(_p2, _p3, t);
			
			var p02:Point = Point.interpolate(p01, p11, t);
			var p12:Point = Point.interpolate(p11, p21, t);
			
			var p03:Point = Point.interpolate(p02, p12, t);
			
			return Vector.<CubicBezierSegment>([
				new CubicBezierSegment(_p0.clone(), p01, p02, p03.clone()),
				new CubicBezierSegment(p03, p12, p21, _p3.clone())
			]);
		}
		
		
		public function splitByLength(length:Number):Vector.<CubicBezierSegment> {
			return split(length / getLength());
		}
		
		
		public function reverse():void {
			var tmp:Point;
			tmp = _p0;
			_p0 = _p3;
			_p3 = tmp;
			tmp = _p1;
			_p1 = _p2;
			_p2 = tmp;
		}
		
		
		public function transform(matrix:Matrix):void {
			p0 = matrix.transformPoint(_p0);
			p1 = matrix.transformPoint(_p1);
			p2 = matrix.transformPoint(_p2);
			p3 = matrix.transformPoint(_p3);
		}
		
		
		public function clone(reverse:Boolean = false):CubicBezierSegment {
			if (reverse) {
				return new CubicBezierSegment(_p3.clone(), _p2.clone(), _p1.clone(), _p0.clone());
			} else {
				return new CubicBezierSegment(_p0.clone(), _p1.clone(), _p2.clone(), _p3.clone());
			}
		}
		
		
		public function toCubicHermite():CubicHermite {
			return new CubicHermite(
				_p0.clone(),
				new Point(3 * (_p1.x - _p0.x), 3 * (_p1.y - _p0.y)),
				_p3.clone(),
				new Point(3 * (_p3.x - _p2.x), 3 * (_p3.y - _p2.y))
			);
		}

		
		public function setPoints(points:Vector.<Point>):void {
			p0 = points[0];
			p1 = points[1];
			p2 = points[2];
			p3 = points[3];
		}


		public function readExternal(input:IDataInput):void {
			_p0.x = input.readFloat();
			_p0.y = input.readFloat();
			_p1.x = input.readFloat();
			_p1.y = input.readFloat();
			_p2.x = input.readFloat();
			_p2.y = input.readFloat();
			_p3.x = input.readFloat();
			_p3.y = input.readFloat();
		}


		public function writeExternal(output:IDataOutput):void {
			output.writeFloat(_p0.x);
			output.writeFloat(_p0.y);
			output.writeFloat(_p1.x);
			output.writeFloat(_p1.y);
			output.writeFloat(_p2.x);
			output.writeFloat(_p2.y);
			output.writeFloat(_p3.x);
			output.writeFloat(_p3.y);
		}

		
		override flash_proxy function getProperty(name:*):* {
			var index:int = int(name);
			if (index < 0 || 3 < index || !(name is String)) throw new ArgumentError('Prop name must be int in range 0 to 3.');
			return _points[index];
		}

		
		override flash_proxy function setProperty(name:*, value:*):void {
			var index:int = int(name);
			if (index < 0 || 3 < index || !(name is String)) throw new ArgumentError('Prop name must be int in range 0 to 3.');
			if (!(value is Point)) throw new ArgumentError('Value must be instance of flash.geom.Point.');
			_points[index].x = value.x;			_points[index].y = value.y;
		}

		
		override flash_proxy function nextNameIndex(index:int):int {
			return 0;
		}
		
		
		public function toString():String {
			return '[CubicBezier p0=' + _p0 + ' p1=' + _p1 + ' p2=' + _p2 + ' p3=' + _p3 + ']';
		}
		
		
		//
		

		/**
		 * Draw using native cubicCurveTo method. (incuvator release only)
		 */		
		private static function __drawNative(graphics:Graphics, p0:Point, p1:Point, p2:Point, p3:Point):void {
			graphics['cubicCurveTo'](p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
		}
		

		/**
		 * Draw the cubic bezier with approximation by quadratic curves using fixed mid-point approach.
		 * @see http://www.timotheegroleau.com/Flash/articles/cubic_bezier_in_flash.htm
		 */
		private static function __draw1(graphics:Graphics, p0:Point, p1:Point, p2:Point, p3:Point):void {
			// calculates the useful base points
			var PA:Point = Point.interpolate(p1, p0, 3 / 4);
			var PB:Point = Point.interpolate(p2, p3, 3 / 4);
			
			// get 1/16 of the [P3, P0] segment
			var dx:Number = (p3.x - p0.x) / 16;
			var dy:Number = (p3.y - p0.y) / 16;
			
			// calculates control point 1
			var Pc_1:Point = Point.interpolate(p1, p0, 3 / 8);
			
			// calculates control point 2
			var Pc_2:Point = Point.interpolate(PB, PA, 3 / 8);
			Pc_2.x -= dx;
			Pc_2.y -= dy;
			
			// calculates control point 3
			var Pc_3:Point = Point.interpolate(PA, PB, 3 / 8);
			Pc_3.x += dx;
			Pc_3.y += dy;
			
			// calculates control point 4
			var Pc_4:Point = Point.interpolate(p2, p3, 3 / 8);
			
			// calculates the 3 anchor points
			var Pa_1:Point = Point.interpolate(Pc_2, Pc_1, 0.5);
			var Pa_2:Point = Point.interpolate(PB, PA, 0.5);
			var Pa_3:Point = Point.interpolate(Pc_4, Pc_3, 0.5);
		
			// draw the four quadratic subsegments
			graphics.curveTo(Pc_1.x, Pc_1.y, Pa_1.x, Pa_1.y);
			graphics.curveTo(Pc_2.x, Pc_2.y, Pa_2.x, Pa_2.y);
			graphics.curveTo(Pc_3.x, Pc_3.y, Pa_3.x, Pa_3.y);
			graphics.curveTo(Pc_4.x, Pc_4.y, p3.x, p3.y);
		}


		/**
		 * Draw the cubic bezier with approximation by quadratic curves using tangent approach.
		 * @see http://www.timotheegroleau.com/Flash/articles/cubic_bezier_in_flash.htm
		 */
		private static function __draw2(graphics:Graphics, p0:Point, p1:Point, p2:Point, p3:Point, nSegment:int = 4):void {
			//define the local variables
			var curT:Object; // holds the current Tangent object
			var nextT:Object; // holds the next Tangent object
			var total:int = 0; // holds the number of slices used
			
			// make sure nSegment is within range (also create a default in the process)
			if (nSegment < 2) nSegment = 4;
			
			// get the time Step from nSegment
			var tStep:Number = 1 / nSegment;
			
			// get the first tangent Object
			curT = new Object();
			curT.P = p0;
			curT.l = Line.getLine(p0, p1);
			
			// move to the first point
			// this.moveTo(P0.x, P0.y);
			
			// get tangent Objects for all intermediate segments and draw the segments
			for (var i:int = 1; i <= nSegment; i++) {
				// get Tangent Object for next point
				nextT = DrawImpl2.getCubicTgt(p0, p1, p2, p3, i * tStep);
				// get segment data for the current segment
				total += DrawImpl2.sliceCubicBezierSegment(graphics, p0, p1, p2, p3, (i - 1) * tStep, i * tStep, curT, nextT, 0);
				// prepare for next round
				curT = nextT;
			}
		}


		/**
		 * Draw the cubic bezier with approximation by quadratic curves using generic mid-point approach by Robert Penner.
		 * @see http://www.robertpenner.com/scripts/bezier_draw_cubic.txt
		 */
		private static function __draw3(graphics:Graphics, p0:Point, p1:Point, p2:Point, p3:Point, tolerance:Number = 5):void {
			DrawImpl3.$cBez(graphics, p0, p1, p2, p3, tolerance * tolerance);
		}
	}
}


import flash.display.Graphics;
import flash.geom.Point;


/**
 * Draw the cubic bezier with approximation by quadratic curves using tangent approach.
 * @see http://www.timotheegroleau.com/Flash/articles/cubic_bezier_in_flash.htm
 */
class DrawImpl2 {


	public static function sliceCubicBezierSegment(graphics:Graphics, P0:Point, P1:Point, P2:Point, P3:Point, u1:Number, u2:Number, Tu1:Object, Tu2:Object, recurs:int):int {
		// prevents infinite recursion (no more than 10 levels)
		// if 10 levels are reached the latest subsegment is 
		// approximated with a line (no quadratic curve). It should be good enough.
		if (recurs > 10) {
			graphics.lineTo(Tu2.P.x, Tu2.P.y);
			return 1;
		}
	
		// recursion level is OK, process current segment
		var ctrlPt:Point = Line.getCrossPoint(Tu1.l, Tu2.l);
		var d:Number = 0;
		
		// A control point is considered misplaced if its distance from one of the anchor is greater 
		// than the distance between the two anchors.
		if ((ctrlPt == null) || 
			(Point.distance(Tu1.P, ctrlPt) > (d = Point.distance(Tu1.P, Tu2.P))) ||
			(Point.distance(Tu2.P, ctrlPt) > d) ) {
	
			// total for this subsegment starts at 0			
			var tot:int = 0;
	
			// If the Control Point is misplaced, slice the segment more
			var uMid:Number = (u1 + u2) / 2;
			var TuMid:Object = getCubicTgt(P0, P1, P2, P3, uMid);
			tot += sliceCubicBezierSegment(graphics, P0, P1, P2, P3, u1, uMid, Tu1, TuMid, recurs + 1);
			tot += sliceCubicBezierSegment(graphics, P0, P1, P2, P3, uMid, u2, TuMid, Tu2, recurs + 1);
			
			// return number of sub segments in this segment
			return tot;
	
		} else {
			// if everything is OK draw curve
			graphics.curveTo(ctrlPt.x, ctrlPt.y, Tu2.P.x, Tu2.P.y);
			return 1;
		}
	}
	

	public static function getCubicTgt(P0:Point, P1:Point, P2:Point, P3:Point, t:Number):Object {
	
		// calculates the position of the cubic bezier at t
		var P:Point = new Point();
		P.x = getCubicPt(P0.x, P1.x, P2.x, P3.x, t);
		P.y = getCubicPt(P0.y, P1.y, P2.y, P3.y, t);
		
		// calculates the tangent values of the cubic bezier at t
		var V:Point = new Point();
		V.x = getCubicDerivative(P0.x, P1.x, P2.x, P3.x, t);
		V.y = getCubicDerivative(P0.y, P1.y, P2.y, P3.y, t);
	
		// calculates the line equation for the tangent at t
		var l:Line = Line.getLine2(P, V);
		
		// return the Point/Tangent object 
		var o:Object = {};
		o.P = P;
		o.l = l;
		
		return o;
	}


	private static function getCubicPt(c0:Number, c1:Number, c2:Number, c3:Number, t:Number):Number {
		var ts:Number = t * t;
		var g:Number = 3 * (c1 - c0);
		var b:Number = (3 * (c2 - c1)) - g;
		var a:Number = c3 - c0 - b - g;
		return (a * ts * t + b * ts + g * t + c0);
	}
	

	private static function getCubicDerivative(c0:Number, c1:Number, c2:Number, c3:Number, t:Number):Number {
		var g:Number = 3 * (c1 - c0);
		var b:Number = (3 * (c2 - c1)) - g;
		var a:Number = c3 - c0 - b - g;
		return (3 * a * t * t + 2 * b * t + g);
	}
}

class Line {

	
	public var a:Number = NaN;
	public var b:Number = NaN;
	public var c:Number = NaN;


	public function Line() {
	}


	public static function getLine(P0:Point, P1:Point):Line {
		var l:Line = new Line();
		var x0:Number = P0.x;
		var y0:Number = P0.y;
		var x1:Number = P1.x;
		var y1:Number = P1.y;
		
		if (x0 == x1) {
			if (y0 == y1) {
				// P0 and P1 are same point, return null
				l = null;
			} else {
				// Otherwise, the line is a vertical line
				l.c = x0;
			}
		} else {
			l.a = (y0 - y1) / (x0 - x1);
			l.b = y0 - (l.a * x0);
		}
		// returns the line object
		return l;
	}


	public static function getLine2(P0:Point, v0:Point):Line {
		var l:Line = new Line();
		var x0:Number = P0.x;
		var vx0:Number = v0.x;
		if (vx0 == 0) {
			// the line is vertical
			l.c = x0;
		} else {
			l.a = v0.y / vx0;
			l.b = P0.y - (l.a * x0);
		}
		// returns the line object
		return l;
	}


	public static function getCrossPoint(l0:Line, l1:Line):Point {
		// Make sure both line exists
		if ((l0 == null) || (l1 == null)) return null;
	
		// define local variables
		var a0:Number = l0.a;
		var b0:Number = l0.b;
		var c0:Number = l0.c;
		var a1:Number = l1.a;
		var b1:Number = l1.b;
		var c1:Number = l1.c;
		var u:Number;
	
		// checks whether both lines are vertical
		if (isNaN(c0) && isNaN(c1)) {
			// lines are not verticals but parallel, intersection does not exist
			if (a0 == a1) return null; 
			// calculate common x value.
			u = (b1 - b0) / (a0 - a1);		
			// return the new Point
			return new Point(u, a0 * u + b0);
	
		} else {
			if (!isNaN(c0)) {
				if (!isNaN(c1)) {
					// both lines vertical, intersection does not exist
					return null;
				} else {
					// return the point on l1 with x = c0
					return new Point(c0, a1 * c0 + b1);
				}
			} else if (!isNaN(c1)) {//c1 != undefined) {
				// no need to test c0 as it was tested above
				// return the point on l0 with x = c1
				return new Point(c1, a0 * c1 + b0);
			}
		}
		
		return null;
	}
}


/**
 * Draw the cubic bezier with approximation by quadratic curves using generic mid-point approach by Robert Penner.
 * @see http://www.robertpenner.com/scripts/bezier_draw_cubic.txt
 */
class DrawImpl3 {

	
	public static function $cBez(graphics:Graphics, a:Point, b:Point, c:Point, d:Point, k:Number):void {
		// find intersection between bezier arms
		var s:Point = intersect2Lines(a, b, c, d);
		if (!s) return;
		// find distance between the midpoints
		var dx:Number = (a.x + d.x + s.x * 4 - (b.x + c.x) * 3) * .125;
		var dy:Number = (a.y + d.y + s.y * 4 - (b.y + c.y) * 3) * .125;
		// split curve if the quadratic isn't close enough
		if (dx*dx + dy*dy > k) {
			var halves:Object = bezierSplit(a, b, c, d);
			var b0:Object = halves.b0;
			var b1:Object = halves.b1;
			// recursive call to subdivide curve
			$cBez(graphics, a, b0.b, b0.c, b0.d, k);
			$cBez(graphics, b1.a, b1.b, b1.c, d, k);
		} else {
			// end recursion by drawing quadratic bezier
			graphics.curveTo(s.x, s.y, d.x, d.y);
		}
	}


	private static function intersect2Lines(p1:Point, p2:Point, p3:Point, p4:Point):Point {
		var x1:Number = p1.x;
		var y1:Number = p1.y;
		var x4:Number = p4.x;
		var y4:Number = p4.y;
	
		var dx1:Number = p2.x - x1;
		var dx2:Number = p3.x - x4;
		if (!(dx1 || dx2)) return null;
		
		var m1:Number = (p2.y - y1) / dx1;
		var m2:Number = (p3.y - y4) / dx2;
		
		if (!dx1) {
			// infinity
			return new Point(x1, m2 * (x1 - x4) + y4);
		} else if (!dx2) {
			// infinity
			return new Point(x4, m1 * (x4 - x1) + y1);
		}
		var xInt:Number = (-m2 * x4 + y4 + m1 * x1 - y1) / (m1 - m2);
		var yInt:Number = m1 * (xInt - x1) + y1;
		return new Point(xInt, yInt);
	}


	private static function bezierSplit(p0:Point, p1:Point, p2:Point, p3:Point):Object {
		var p01:Point = Point.interpolate(p0, p1, 0.5);
		var p12:Point = Point.interpolate(p1, p2, 0.5);
		var p23:Point = Point.interpolate(p2, p3, 0.5);
		var p02:Point = Point.interpolate(p01, p12, 0.5);
		var p13:Point = Point.interpolate(p12, p23, 0.5);
		var p03:Point = Point.interpolate(p02, p13, 0.5);
		return {
			b0: {a: p0,  b: p01, c: p02, d: p03},
			b1: {a: p03, b: p13, c: p23, d: p3}
		};
	}
}
