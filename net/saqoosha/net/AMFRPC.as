package net.saqoosha.net {
	import net.saqoosha.logging.dump;

	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.ObjectEncoding;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;

	[Event(name="error", type="flash.events.ErrorEvent")]
	[Event(name="ioError", type="flash.events.IOErrorEvent")]
	[Event(name="securityError", type="flash.events.SecurityErrorEvent")]
	[Event(name="progress", type="flash.events.ProgressEvent")]
	[Event(name="complete", type="flash.events.Event")]

	
	/**
	 * @author hiko
	 */
	public class AMFRPC extends EventDispatcher {
		
		
		public static var DEFAULT_GATEWAY:String;
		
		public static var DEBUG_OUT:Boolean = false;
		
		private static var NEXT_RESPONCE_ID:int = 1;
		
		
		private var _gateway:String;
		private var _loader:URLLoader;
		private var _isError:Boolean = false;
		private var _result:*;

		
		public function AMFRPC(gateway:String = null) {
			_gateway = gateway || DEFAULT_GATEWAY;
			
			_loader = new URLLoader();
			_loader.dataFormat = URLLoaderDataFormat.BINARY;
			_loader.addEventListener(IOErrorEvent.IO_ERROR, dispatchEvent);
			_loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, dispatchEvent);
			_loader.addEventListener(ProgressEvent.PROGRESS, dispatchEvent);
			_loader.addEventListener(Event.COMPLETE, _onComplete);
		}
		
		
		public function call(remoteMethod:String, ...args):void {
			var bodyByte:ByteArray = new ByteArray();
			bodyByte.objectEncoding = ObjectEncoding.AMF0; 
			bodyByte.writeByte(0x0A); // AMF0 array type
			bodyByte.writeInt(args.length); // length of AMF0 arguments array
			for each (var arg:* in args) {
				bodyByte.writeObject(arg);
			}
			
			var responseId:String = '/' + NEXT_RESPONCE_ID++; // responce ID
			
			var messageByte:ByteArray = new ByteArray();
			messageByte.objectEncoding = ObjectEncoding.AMF0; // shold be AMF0
			messageByte.writeShort(0x03); // AMF version
			messageByte.writeShort(0x00); // Number of headers (No header)
			messageByte.writeShort(0x01); // Number of body
			messageByte.writeUTF(remoteMethod); // remote method name
			messageByte.writeUTF(responseId); // responce id
			messageByte.writeInt(bodyByte.length); // size of serialized body
			messageByte.writeBytes(bodyByte); // serialized body data
			
			var request:URLRequest = new URLRequest(_gateway);
			request.method=URLRequestMethod.POST;
			request.data = messageByte;
			request.requestHeaders = [new URLRequestHeader('Content-Type', 'application/x-amf')];
			
			_loader.load(request);
		}

		
		protected function _onComplete(event:Event):void {
			_parseResponse(_loader.data);
			if (_isError) {
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, _result.description));
			} else {
				dispatchEvent(event);
			}
		}

		
		private function _parseResponse(data:ByteArray):void {
			data.objectEncoding = ObjectEncoding.AMF0;
			var amfVersion:int = data.readShort();
			var numHeaders:int = data.readShort();
			for (var i:int = 0; i < numHeaders; ++i) {
				_readHeader(data);
			}
			var numBodies:int = data.readShort(); // always 1?
			for (i = 0; i < numBodies; ++i) {
				_readBody(data);
			}
		}

		
		private function _readHeader(data:ByteArray):void {
			if (DEBUG_OUT) trace('_readHeader: from', data.position.toString(16));
			var name:String = data.readUTF();
			var required:Boolean = data.readBoolean();
			var length:int = data.readInt();
			var content:* = data.readObject();
			if (DEBUG_OUT) dump({
				name: name,
				required: required,
				length: length,
				content: content
			});
		}

		
		private function _readBody(data:ByteArray):void {
			if (DEBUG_OUT) trace('_readBody: from', data.position.toString(16));
			var target:String = data.readUTF();
			_isError = target.split('/')[2] != 'onResult';
			var response:String = data.readUTF();
			var length:int = data.readInt();
			if (data[data.position] == 0x11) { // AVM+ marker?
				data.position++;
				data.objectEncoding = ObjectEncoding.AMF3;
			}
			_result = data.readObject();
			if (DEBUG_OUT) dump({
				target: target,
				response: response,
				length: length,
				content: _result
			});
			data.objectEncoding = ObjectEncoding.AMF0;
		}
		
		
		public function get result():* {
			return _result;
		}
	}
}