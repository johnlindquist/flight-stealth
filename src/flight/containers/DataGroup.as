/*
 * Copyright (c) 2010 the original author or authors.
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package flight.containers
{
	import flash.display.DisplayObject;
	import flash.events.Event;

	import flight.data.DataChange;
	import flight.display.InitializePhase;
	import flight.display.RenderPhase;
	import flight.list.ArrayList;
	import flight.list.IList;
	
	/**
	 * @alpha - DataGroup is currently non-functional
	 */
	public class DataGroup extends Group
	{
		public function DataGroup()
		{
			addEventListener(InitializePhase.CREATE, onCreate);
		}
		
		[ArrayElementType("Object")]
		[Bindable(event="dataProviderChange", style="noEvent")]
		public function get dataProvider():IList { return _dataProvider ||= new ArrayList(); }
		public function set dataProvider(value:*):void
		{
			RenderPhase.invalidate(this, InitializePhase.CREATE);
			if (!(value is IList) && value !== null) {
				if (!_dataProvider) {
					_dataProvider = new ArrayList();
				}
				if (value is Array) {
					_dataProvider.addItems(value);
				} else {
					_dataProvider.addItem(value);
				}
				DataChange.change(this, "dataProvider", _dataProvider, _dataProvider, true);
			} else {
				DataChange.change(this, "dataProvider", _dataProvider, _dataProvider = value, true);
			}
		}
		private var _dataProvider:IList;
		
		[Bindable(event="templateChange", style="noEvent")]
		public function get template():Object { return _template }
		public function set template(value:Object):void
		{
			RenderPhase.invalidate(this, InitializePhase.CREATE);
			DataChange.change(this, "template", _template, _template = value as Class);
		}
		private var _template:Class;
		
		protected function create():void
		{
			if (_dataProvider && _template) {
				
				var child:DisplayObject;
				for (var i:int = 0; i < _dataProvider.length; i++) {
					
					child = i < numChildren ? getChildAt(i) : null;
					if (!(child is _template)) {
						child = new _template();
						addChildAt(child, i);
					}
					if ("data" in child) {
						child["data"] = _dataProvider.getItemAt(i);
					}
				}
				
				while (i < numChildren) {
					removeChildAt(i);
				}
			}
		}
		
		private function onCreate(event:Event):void
		{
			create();
		}
	}
}
