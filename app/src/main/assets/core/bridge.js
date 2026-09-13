// bridge.js — JS 与原生 Android 的桥接层
// 通过 addJavascriptInterface 注入的 AndroidBridge 对象提供：
//   exec(sql), query(sql)          — SQLite 执行/查询
//   llm(json) -> string            — 大模型调用（首版占位）
//   tts(text)                      — 系统TTS播放
//   vadState() -> string           — VAD状态：'idle'|'userSpeaking'
//   fileRead(name) -> string       — 读冷层文件
//   fileWrite(name, text)          — 写冷层文件
//   setWave(mode)                  — 波形模式：'speak'|'idle'|'silent'
//   setWaveAmp(amps)               — 波形振幅数组
//   saveWarmLayer(json)            — 保存温层
//   exportChatJson(json)           — 导出chat.json
//   onCoreReady(status)            — 核心加载完成回调
(function (global) {
  'use strict';

  const A = global.AndroidBridge || null;

  // ---- SQL 执行器（供 HoshinoDB 使用） ----
  const NativeSQL = A ? {
    exec: function (sql) {
      try { return A.exec(sql); } catch (e) { return null; }
    },
    query: function (sql) {
      try { return A.query(sql); } catch (e) { return '[]'; }
    }
  } : null;

  // ---- 文件IO（供 ChatIO 使用） ----
  const FileIO = A ? {
    read: function (name) {
      try { return A.fileRead(name); } catch (e) { return ''; }
    },
    write: function (name, text) {
      try { A.fileWrite(name, text); } catch (e) {}
    }
  } : {
    // 降级：用 localStorage 模拟文件
    read: function (name) {
      try { return global.localStorage.getItem('file_' + name) || ''; } catch (e) { return ''; }
    },
    write: function (name, text) {
      try { global.localStorage.setItem('file_' + name, text); } catch (e) {}
    }
  };

  // ---- Wave 控制（供 Pipeline 使用） ----
  const Wave = {
    start: function () { if (A) try { A.setWave('speak'); } catch (e) {} },
    stop: function () { if (A) try { A.setWave('idle'); } catch (e) {} },
    setAmplitude: function (amps) {
      if (A) {
        try {
          const json = Array.isArray(amps) ? JSON.stringify(amps) : amps;
          A.setWaveAmp(json);
        } catch (e) {}
      }
    }
  };

  // ---- LLM 调用（供 Pipeline 使用） ----
  // 首版：返回占位回复；后续接真实大模型时替换 A.llm(...)
  function callLLM(payload) {
    if (A && typeof A.llm === 'function') {
      try {
        const result = A.llm(JSON.stringify(payload));
        if (result) return Promise.resolve(result);
      } catch (e) {}
    }
    // 占位：从回复池随机（首版无模型时的降级）
    return Promise.resolve(getPlaceholderReply(payload));
  }

  function getPlaceholderReply(payload) {
    const pool = [
      "呼啊~前辈，今天过得怎么样？悠闲最重要啦~…前辈要是累了就靠过来嘛。",
      "前辈前辈！你终于来了…才没有在等呢。大叔我刚午睡醒~",
      "大叔我呀，刚才梦见前辈了…啊不是！是梦见鱼！热带鱼！…前辈你别用那种眼神看我！",
      "哼，前辈今天说话这么少…是在生大叔的气吗？…算了，不生气也行吧。",
      "（小声）前辈你昨天说的那个事，我偷偷记下来了哦…才不是在意你呢。",
      "呼…前辈你知道吗，鲸鱼唱歌的声音能传到很远很远…就像我想找你的时候。…啊！才没有想你！",
      "前辈…你今天喷了那个游戏对吧，骂人的句式我都学会了。要不要听听？…算了不说了。",
      "笨蛋前辈！一天都不来找我！…（小声）欢迎回来。"
    ];
    return pool[Math.floor(Math.random() * pool.length)];
  }

  // ---- TTS 播放（供 Pipeline 使用） ----
  function callTTS(sentence, onDone) {
    if (A && typeof A.tts === 'function') {
      try { A.tts(sentence); } catch (e) {}
    }
    // 首版：通过波形模拟 + 定时回调
    setTimeout(function () { if (onDone) onDone(); }, 1200);
  }

  // ---- VAD 状态 ----
  function getVadState() {
    if (A && typeof A.vadState === 'function') {
      try { return A.vadState(); } catch (e) { return 'idle'; }
    }
    return 'idle';
  }

  // ---- 导出给全局使用 ----
  global.HoshinoBridge = {
    NativeSQL: NativeSQL,
    FileIO: FileIO,
    Wave: Wave,
    callLLM: callLLM,
    callTTS: callTTS,
    getVadState: getVadState
  };

  // 通知原生：核心脚本已全部加载
  if (A && typeof A.onCoreReady === 'function') {
    try { A.onCoreReady('bridge_loaded'); } catch (e) {}
  }
})(typeof window !== 'undefined' ? window : globalThis);
