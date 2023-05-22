using Discord.WebSocket;
using Discord;
using Newtonsoft.Json.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System;

using System;
using System.Threading.Tasks;
using Discord;
using Discord.WebSocket;
using System.Net.Http;
using Newtonsoft.Json.Linq;
using System.Timers;
using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;

class Program
{
    private DiscordSocketClient _client;
    private string _token = "";
    private ulong _channelId = 123123123;
    private HttpClient _httpClient;
    private Timer _timer;

    static void Main(string[] args) => new Program().RunBotAsync().GetAwaiter().GetResult();

    public async Task RunBotAsync()
    {
        _client = new DiscordSocketClient();
        _client.Log += Log;

        _httpClient = new HttpClient();

        await RegisterCommandsAsync();
        await _client.LoginAsync(TokenType.Bot, _token);
        await _client.StartAsync();
        await Task.Delay(-1);
    }

    private Task Log(LogMessage arg)
    {
        Console.WriteLine(arg);
        return Task.CompletedTask;
    }

    private async Task RegisterCommandsAsync()
    {
        _client.Ready += () =>
        {
            var channelId = _client.GetChannel(_channelId) as IMessageChannel;
            channelId.SendMessageAsync("hi");

            
            var config = JsonConvert.DeserializeObject<Config>(File.ReadAllText("config.json"));
            _timer = new Timer(config.CheckIntervalInMinutes * 60 * 1000); 
            _timer.Elapsed += async (sender, e) => await GetEvents();
            _timer.Start();

            return Task.CompletedTask;
        };
    }

    private async Task GetEvents()
    {
        var response = await _httpClient.GetAsync("https://www.robotevents.com/api/v2/events?region=4&grade_level=ms,hs");
        var json = await response.Content.ReadAsStringAsync();
        var eventsObject = JObject.Parse(json);
        var eventsData = (JArray)eventsObject["data"];
        var channelId = _client.GetChannel(_channelId) as IMessageChannel;

        if (eventsData.Count == 0)
        {
            await channelId.SendMessageAsync("No events are currently listed.");
        }
        else
        {
            await channelId.SendMessageAsync("Current events:");
            foreach (var eventData in eventsData)
            {
                await channelId.SendMessageAsync($"{eventData["name"]}");
            }
        }
    }
}

class Config
{
    public double CheckIntervalInMinutes { get; set; }
}
