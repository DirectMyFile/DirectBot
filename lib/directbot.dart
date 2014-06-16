#!/usr/bin/env dart
library directbot;

import 'package:irc/irc.dart';
import 'dart:io';
import 'dart:convert';
import "package:yaml/yaml.dart";

part "youtube.dart";
part 'config.dart';

var http = new HttpClient();

check_user(event) {
  if (!config['admins'].contains(event.from)) {
    event.reply("> ${Color.RED}Sorry, you don't have permission to do that${Color.RESET}.");
    return false;
  }
  return true;
}

start() {
  load_config();

  BotConfig botConf = new BotConfig(
    nickname: config["nickname"],
    username: config["username"],
    host: config["host"],
    port: int.parse(config["port"].toString())
  );

  print("Starting DirectBot on ${botConf.host}:${botConf.port}");

  print("Going to Join: ${config['channels'].join(', ')}");

  CommandBot bot = new CommandBot(botConf);

  bot.prefix = config['commands']['prefix'];

  bot.register((ReadyEvent event) {
    for (String channel in config['channels']) {
      bot.join(channel);
    }
    bot.client().identify(username: config["identity"]["username"], password: config["identity"]["password"]);
  });

  bot.register((BotJoinEvent event) {
    print("Joined ${event.channel.name}");
  });

  bot.register((BotPartEvent event) {
    print("Left ${event.channel.name}");
  });

  if (config["debug"]) {
    bot.register((LineReceiveEvent event) {
      print(">> ${event.line}");
    });

    bot.register((LineSentEvent event) {
      print("<< ${event.line}");
    });
  }

  bot.register((ConnectEvent event) {
    print("Connected");
  });

  bot.register((DisconnectEvent event) {
    print("Disconnected");
  });

  bot.command("help").listen((CommandEvent event) {
    event.reply("> ${Color.BLUE}Commands${Color.RESET}: ${bot.commandNames().join(', ')}");
  });

  bot.command("join").listen((event) {
    if (!check_user(event)) return;
    if (event.args.length != 1) {
      event.reply("> Usage: join <channel>");
    } else {
      bot.join(event.channel);
    }
  });

  bot.command("part").listen((event) {
    if (!check_user(event)) return;
    if (event.args.length != 1) {
      event.reply("> Usage: part <channel>");
    } else {
      bot.part(event.channel);
    }
  });

  bot.command("quit").listen((event) {
    if (!check_user(event)) return;
    bot.disconnect();
  });


  bot.register((MessageEvent event) {
    /* YouTube Support */
    if (!event.message.startsWith(bot.prefix)) {
      handle_youtube(event);
    }
    print("<${event.target}><${event.from}> ${event.message}");
  });

  bot.connect();
}
