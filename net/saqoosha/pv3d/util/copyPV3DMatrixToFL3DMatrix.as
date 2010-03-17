package net.saqoosha.pv3d.util {
	import org.papervision3d.core.math.Matrix3D;

	import flash.geom.Matrix3D;

	/**
	 * @author hiko
	 */
	public function copyPV3DMatrixToFL3DMatrix(pv3dmatrix:org.papervision3d.core.math.Matrix3D, fl3dmatrix:flash.geom.Matrix3D = null):flash.geom.Matrix3D {
		var p:org.papervision3d.core.math.Matrix3D = pv3dmatrix;
		fl3dmatrix ||= new flash.geom.Matrix3D();
		var f:Vector.<Number> = fl3dmatrix.rawData;
		f[0]  =  p.n11;  f[1]  = -p.n21;  f[2]  =  p.n31;  f[3]  =  p.n41;
		f[4]  = -p.n12;  f[5]  =  p.n22;  f[6]  = -p.n32;  f[7]  =  p.n42;
		fl3dmatrix.rawData = f;
		return fl3dmatrix;
	}
}