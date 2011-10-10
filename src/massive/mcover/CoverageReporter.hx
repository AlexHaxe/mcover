package massive.mcover;

import massive.mcover.client.TraceClient;
import massive.mcover.CoverageReportClient;
import massive.mcover.util.Timer;
import massive.mcover.data.AllClasses;

import massive.mcover.data.CoverageResult;

import massive.mcover.data.Package;
import massive.mcover.data.File;
import massive.mcover.data.Clazz;
import massive.mcover.data.Method;
import massive.mcover.data.Statement;
import massive.mcover.data.Branch;
import massive.mcover.MCover;

import massive.mcover.Exception;

interface CoverageReporter
{
	/*
	 * Handler which if present, should be called when the client has completed its processing of the results.
	 */
	var completionHandler(default, default):Float -> Void;
	
	var allClasses(default, null):AllClasses;

	var logger(default, null):CoverageLogger;


	function initialize(logger:CoverageLogger, allClasses:AllClasses):Void;

	function report():Void;

	/**
	 * Add a coverage clients to interpret coverage results.
	 * 
	 * @param client  client to interpret coverage results 
	 * @see massive.mcover.CoverageReportClient
	 * @see massive.mcover.client.PrintClient
	 */
	function addClient(client:CoverageReportClient):Void;
	function removeClient(client:CoverageReportClient):Void;
	function getClients():Array<CoverageReportClient>;

	/**
	* Removes timers and contents
	*/
	function destroy():Void;
}

class CoverageReporterImpl implements CoverageReporter
{
	/**
	 * Handler called when all clients 
	 * have completed processing the results.
	 */
	public var completionHandler(default, default):Float -> Void;

	public var allClasses(default, null):AllClasses;
	public var logger(default, null):CoverageLogger;

	var clients:Array<CoverageReportClient>;
	var clientCompleteCount:Int;

	/**
	 * Class constructor.
	 */
	public function new()
	{
		clients = [];
	}

	public function initialize(logger:CoverageLogger, allClasses:AllClasses)
	{
		this.logger = logger;
		this.allClasses = allClasses;
	}

	public function report()
	{
		if(logger == null) throw new Exception("Runner has not been initialized");

		if(allClasses == null) throw new Exception("Runner has not been initialized");

		if(clients.length == 0)
		{
			var client = new TraceClient();
			client.completionHandler = clientCompletionHandler;
			clients.push(client);
		}
		generateReport();
	}

	public function addClient(client:CoverageReportClient)
	{
		for(c in clients)
		{
			if(c == client) return;
		}

		client.completionHandler = clientCompletionHandler;
		clients.push(client);
	}

	public function removeClient(client:CoverageReportClient)
	{
		client.completionHandler = null;
		clients.remove(client);
	}

	public function getClients():Array<CoverageReportClient>
	{
		return clients.concat([]);
	}

	public function destroy()
	{
		for(c in clients)
		{
			c.completionHandler = null;
		}

		clients = [];
	}

	///////////////////////////////////

	function generateReport()
	{
		allClasses.getResults(true);

		clientCompleteCount = 0;
			
		for (client in clients)
		{	
			client.report(allClasses);
		}
	}

	function clientCompletionHandler(client:CoverageReportClient):Void
	{
		clientCompleteCount ++;
		
		if (clientCompleteCount == clients.length)
		{
			if (completionHandler != null)
			{
				executeCompletionHandler();
				//Timer.delay(executeCompletionHandler, 1);
			}
		}
	}

	function executeCompletionHandler()
	{
		var percent:Float = allClasses.getPercentage();
		completionHandler(percent);
	}

	/////////////// DEBUGGING METHODS  ////////////

	@IgnoreCover
	function debug(value:Dynamic)
	{
		#if MCOVER_DEBUG
		trace(Std.string(value) + " time: " + Timer.stamp());
		#end
	}
}