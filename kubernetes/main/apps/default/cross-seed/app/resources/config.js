module.exports = {
  delay: 20,
  qbittorrentUrl: "http://qbittorrent.default.svc.cluster.local:8080",
  torznab: [
    `https://prowlarr.robsonhome.cloud/3/api?apikey=$${process.env.PROWLARR_API_KEY}`, // mam
    `https://prowlarr.robsonhome.cloud/5/api?apikey=$${process.env.PROWLARR_API_KEY}`, // hds
    `https://prowlarr.robsonhome.cloud/9/api?apikey=$${process.env.PROWLARR_API_KEY}`, // ipt
    `https://prowlarr.robsonhome.cloud/11/api?apikey=$${process.env.PROWLARR_API_KEY}`, // dc
    `https://prowlarr.robsonhome.cloud/14/api?apikey=$${process.env.PROWLARR_API_KEY}`, // thhq
    `https://prowlarr.robsonhome.cloud/16/api?apikey=$${process.env.PROWLARR_API_KEY}`, // tos
    `https://prowlarr.robsonhome.cloud/17/api?apikey=$${process.env.PROWLARR_API_KEY}`, // mlk
    `https://prowlarr.robsonhome.cloud/53/api?apikey=$${process.env.PROWLARR_API_KEY}`, // fnp
    `https://prowlarr.robsonhome.cloud/86/api?apikey=$${process.env.PROWLARR_API_KEY}`, // uplcx
  ],
  port: process.env.CROSSSEED_PORT || 80,
  apiAuth: false,
  action: "inject",
  includeEpisodes: false,
  includeSingleEpisodes: true,
  includeNonVideos: true,
  duplicateCategories: true,
  matchMode: "safe",
  skipRecheck: true,
  outputDir: "/config",
  torrentDir: "/qbittorrent/qBittorrent/BT_backup",
}