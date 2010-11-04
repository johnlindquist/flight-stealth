﻿/*
 * Copyright (c) 2010 the original author or authors.
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package flight.skins
{
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import flight.containers.IContainer;
	import flight.data.DataBind;
	import flight.data.DataChange;
	import flight.display.LayoutPhase;
	import flight.display.RenderPhase;
	import flight.events.ListEvent;
	import flight.events.ListEventKind;
	import flight.layouts.Bounds;
	import flight.layouts.DockLayout;
	import flight.layouts.IBounds;
	import flight.layouts.ILayout;
	import flight.layouts.IMeasureable;
	import flight.list.ArrayList;
	import flight.list.IList;
	import flight.styles.IStateful;
	
	[Event(name="skinPartChange", type="flight.events.SkinEvent")]
	
	/**
	 * Skin is a convenient base class for many skins, swappable graphic
	 * definitions. Skins decorate a target Sprite by drawing on its surface,
	 * adding children to the Sprite, or both.
	 */
	[DefaultProperty("content")]
	public class Skin extends EventDispatcher implements ISkin, IContainer, IStateful
	{
		protected var dataBind:DataBind = new DataBind();
		
		public function Skin()
		{
			_measured = new Bounds();
			_content = new ArrayList();
			dataBind.bind(this, "currentState", this, "target.currentState");
		}
		
		// ====== ISkin implementation ====== //
		
		[Bindable(event="targetChange", style="noEvent")]
		public function get target():Sprite { return _target; }
		public function set target(value:Sprite):void
		{
			if (_target != value) {
				if (_target) {
					detachSkin();
				}
				DataChange.queue(this, "display", _target, value);
				DataChange.queue(this, "target", _target, _target = value);
				if ("hostComponent" in this) {
					this["hostComponent"] = _target;
				}
				if (_target) {
					attachSkin();
				}
				if (_layout && _target) {
					_layout.target = this;
				}
				DataChange.change();
			}
		}
		private var _target:Sprite;
		
		public function getSkinPart(partName:String):InteractiveObject
		{
			return partName in this ? this[partName] : null;
		}
		
		protected function attachSkin():void
		{
			for (var i:int = 0; i < _target.numChildren; i ++) {
				_content.addItemAt(_target.getChildAt(i), i);
			}
			for (i; i < _content.length; i++) {
				_target.addChildAt(DisplayObject(_content.getItemAt(i)), i);
			}
			_target.addEventListener(Event.ADDED, onChildAdded, true);
			_target.addEventListener(Event.REMOVED, onChildRemoved, true);
			_content.addEventListener(ListEvent.LIST_CHANGE, onContentChange);
		}
		
		protected function detachSkin():void
		{
			_target.removeEventListener(Event.ADDED, onChildAdded, true);
			_target.removeEventListener(Event.REMOVED, onChildRemoved, true);
			_content.removeEventListener(ListEvent.LIST_CHANGE, onContentChange);
			
			while (_target.numChildren) {
				_target.removeChildAt(0);
			}
		}
		
		// ====== IStateful implementation ====== //
		
		[Bindable(event="currentStateChange", style="noEvent")]
		public function get currentState():String { return _currentState; }
		public function set currentState(value:String):void
		{
			DataChange.change(this, "currentState", _currentState, _currentState = value);
		}
		private var _currentState:String;
		
		[Bindable(event="statesChange", style="noEvent")]
		public function get states():Array { return _states; }
		public function set states(value:Array):void
		{
			DataChange.change(this, "states", _states, _states = value);
		}
		private var _states:Array;
		
		// ====== IContainer implementation ====== //
		
		/**
		 * @inheritDoc
		 */
		[ArrayElementType("flash.display.DisplayObject")]
		[Bindable(event="contentChange", style="noEvent")]
		public function get content():IList { return _content; }
		public function set content(value:*):void
		{
			_content.removeItems();
			if (value is IList) {
				_content.addItems( IList(value).getItems() );
			} else if (value is Array) {
				_content.addItems(value);
			} else {
				_content.addItem(value);
			}
			DataChange.change(this, "content", _content, _content, true);
		}
		private var _content:IList;
		
		/**
		 * @inheritDoc
		 */
		[Bindable(event="layoutChange", style="noEvent")]
		public function get layout():ILayout { return _layout; }
		public function set layout(value:ILayout):void
		{
			if (_layout != value) {
				if (_layout) {
					_layout.target = null;
				}
				DataChange.queue(this, "layout", _layout, _layout = value);
				if (_layout && _target) {
					_layout.target = this;
				}
				DataChange.change();
			}
		}
		private var _layout:ILayout;
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General")]
		[Bindable(event="widthChange", style="noEvent")]
		public function get contentWidth():Number
		{
			return _target != null ? _target.width : 0;
		}
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General")]
		[Bindable(event="heightChange", style="noEvent")]
		public function get contentHeight():Number
		{
			return _target != null ? _target.height : 0;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get measured():IBounds
		{
			return _target is IMeasureable ? IMeasureable(_target).measured : _measured;
		}
		private var _measured:IBounds;
		
		/**
		 * @inheritDoc
		 */
		[Bindable(event="displayChange", style="noEvent")]
		public function get display():DisplayObject { return _target; }
		
		private function onChildAdded(event:Event):void
		{
			var child:DisplayObject = DisplayObject(event.target);
			if (contentChanging || child.parent != _target) {
				return;
			}
			
			contentChanging = true;
			content.addItemAt(child, _target.getChildIndex(child));
			contentChanging = false;
		}
		
		private function onChildRemoved(event:Event):void
		{
			var child:DisplayObject = DisplayObject(event.target);
			if (contentChanging || child.parent != _target) {
				return;
			}
			
			contentChanging = true;
			content.removeItem(child);
			contentChanging = false;
		}
		
		private function onContentChange(event:ListEvent):void
		{
			if (contentChanging) {
				return;
			}
			
			contentChanging = true;
			var child:DisplayObject;
			var location:int = event.location1;
			switch (event.kind) {
				case ListEventKind.ADD:
					for each (child in event.items) {
						_target.addChildAt(child, location++);
					}
					break;
				case ListEventKind.REMOVE:
					for each (child in event.items) {
						_target.removeChild(child);
					}
					break;
				case ListEventKind.MOVE:
					_target.addChildAt(event.items[0], location);
					if (event.items.length == 2) {
						_target.addChildAt(event.items[1], event.location2);
					}
					break;
				case ListEventKind.REPLACE:
					_target.removeChild(event.items[1]);
					_target.addChildAt(event.items[0], location);
					break;
				default:	// ListEventKind.RESET
					for each (child in event.items) {
						_target.removeChild(child);
					}
					for each (child in _content) {
						_target.addChildAt(child, location++);
					}
			}
			contentChanging = false;
			
			RenderPhase.invalidate(_target, LayoutPhase.MEASURE);
			RenderPhase.invalidate(_target, LayoutPhase.LAYOUT);
		}
		private var contentChanging:Boolean;
	}
}
