//====================================================================--
// dmc_corona/dmc_websockets/html5_js.js
//
// Documentation: https://github.com/dmccuskey/dmc-websockets
//====================================================================--

/*

The MIT License (MIT)

Copyright (C) 2026 Christian Kündig

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

//====================================================================--
//== DMC Corona Library : DMC WebSockets HTML5 Bridge
//====================================================================--

/*

The browser side of dmc_websockets/html5.lua, loaded by Solar2D's HTML5
JS module loader for require('dmc_corona.dmc_websockets.html5_js').

It only moves data: it opens browser WebSockets, sends what it's given
and queues each connection's events until Lua reads them. The state
machine, events and options stay in Lua.

Every call takes one object and returns one object, { ok:true, ... } or
{ ok:false, error:{ kind, name, message } }, since values cross as JSON.
A binary message crosses as a string of characters U+0000-U+00FF, one
per byte.

*/

(function() {

	var NAME = 'dmc_corona_dmc_websockets_html5_js';

	if ( window.hasOwnProperty( NAME ) ) { return; } // loaded already

	var connections = {}; // id -> { ws, events }
	var nextId = 1; // ids are never reused

	// bytes -> string, in pieces: apply() has an argument limit
	var CHUNK = 0x8000;

	function fail( kind, e ) {
		return {
			ok: false,
			error: {
				kind: kind,
				name: ( e && e.name ) || kind,
				message: String( ( e && e.message ) || e || kind )
			}
		};
	}

	function toBinaryString( buffer ) {
		var bytes = new Uint8Array( buffer );
		var parts = [];
		for ( var i = 0; i < bytes.length; i += CHUNK ) {
			parts.push( String.fromCharCode.apply( null, bytes.subarray( i, i + CHUNK ) ) );
		}
		return parts.join( '' );
	}

	function fromBinaryString( str ) {
		var bytes = new Uint8Array( str.length );
		for ( var i = 0; i < str.length; i++ ) {
			bytes[ i ] = str.charCodeAt( i );
		}
		return bytes;
	}

	window[ NAME ] = {

		// { url, protocols } -> { ok, id }
		open: function( params ) {
			var protocols = Array.isArray( params.protocols ) ? params.protocols : [];
			var ws;
			try {
				ws = protocols.length ? new WebSocket( params.url, protocols ) : new WebSocket( params.url );
			} catch ( e ) {
				// eg an invalid URL, or ws:// from an https:// page
				return fail( 'constructor', e );
			}
			ws.binaryType = 'arraybuffer';

			var id = 'ws:' + ( nextId++ );
			var conn = { ws: ws, events: [] };
			connections[ id ] = conn;

			function push( event ) {
				// a disposed connection's late events go nowhere
				if ( connections[ id ] === conn ) { conn.events.push( event ); }
			}

			ws.onopen = function() {
				push( { kind: 'open' } );
			};
			ws.onmessage = function( e ) {
				if ( typeof e.data === 'string' ) {
					push( { kind: 'message', type: 'text', data: e.data } );
				} else {
					// encoded when read, not here
					push( { kind: 'message', type: 'binary', buffer: e.data } );
				}
			};
			ws.onerror = function() {
				push( { kind: 'error' } );
			};
			ws.onclose = function( e ) {
				push( { kind: 'close', code: e.code, reason: e.reason || '', wasClean: !!e.wasClean } );
			};

			return { ok: true, id: id };
		},

		// { id, type:'text'|'binary', data } -> { ok }
		send: function( params ) {
			var conn = connections[ params.id ];
			if ( !conn ) { return fail( 'invalid_id' ); }
			if ( conn.ws.readyState !== 1 ) { return fail( 'not_open' ); }
			try {
				conn.ws.send( params.type === 'binary' ? fromBinaryString( params.data ) : params.data );
			} catch ( e ) {
				return fail( 'send', e );
			}
			return { ok: true };
		},

		// { id, code?, reason? } -> { ok }
		close: function( params ) {
			var conn = connections[ params.id ];
			if ( !conn ) { return fail( 'invalid_id' ); }
			var ws = conn.ws;
			if ( ws.readyState === 2 || ws.readyState === 3 ) { return { ok: true }; }
			try {
				if ( params.code === undefined ) {
					ws.close();
				} else {
					try {
						ws.close( params.code, params.reason || '' );
					} catch ( e ) {
						ws.close( params.code ); // reason over 123 bytes
					}
				}
			} catch ( e ) {
				return fail( 'close', e );
			}
			return { ok: true };
		},

		// { id } -> { ok, events }
		poll: function( params ) {
			var conn = connections[ params.id ];
			if ( !conn ) { return fail( 'invalid_id' ); }
			var events = conn.events;
			conn.events = [];
			for ( var i = 0; i < events.length; i++ ) {
				var event = events[ i ];
				if ( event.buffer ) {
					event.data = toBinaryString( event.buffer );
					delete event.buffer;
				}
			}
			return { ok: true, events: events };
		},

		// { id } -> { ok }, also for an id already disposed
		dispose: function( params ) {
			var conn = connections[ params.id ];
			if ( !conn ) { return { ok: true }; }
			delete connections[ params.id ];
			var ws = conn.ws;
			ws.onopen = ws.onmessage = ws.onerror = ws.onclose = null;
			if ( ws.readyState === 0 || ws.readyState === 1 ) {
				try { ws.close(); } catch ( e ) {}
			}
			return { ok: true };
		}

	};

})();
