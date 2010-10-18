/*
 * Copyright (c) 2010 the original author or authors.
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package flight.containers
{
	import flight.layouts.ILayout;
	import flight.layouts.ILayoutBounds;
	import flight.list.IList;
	
	public interface IContainer extends ILayoutBounds
	{
		function get content():IList;
		
		function get layout():ILayout;
		function set layout(value:ILayout):void;
	}
}
