function parseKaomoji(raw) {
  try {
    var data = JSON.parse(String(raw || ""))
    return Array.isArray(data) ? data : []
  } catch (e) {
    return []
  }
}

function isFuzzySubsequence(text, query) {
  if (!query) return true
  if (!text) return false
  var t = text.toLowerCase()
  var q = query.toLowerCase()
  var ti = 0
  for (var qi = 0; qi < q.length; qi++) {
    ti = t.indexOf(q[qi], ti)
    if (ti < 0) return false
    ti++
  }
  return true
}

function scoreTermAgainstString(target, term) {
  if (!target || !term) return 0
  var str = String(target).toLowerCase()
  var t = String(term).toLowerCase()

  if (str === t) return 100 // Exact match
  if (str.startsWith(t)) return 80 // Prefix match
  if (str.indexOf(" " + t) >= 0 || str.indexOf("-" + t) >= 0 || str.indexOf("_" + t) >= 0) return 70 // Word boundary
  if (str.indexOf(t) >= 0) return 50 // Substring contains
  if (isFuzzySubsequence(str, t)) return 25 // Fuzzy subsequence

  return 0
}

function scoreItem(item, terms) {
  var totalScore = 0
  var cat = item.cat || ""
  var tags = Array.isArray(item.tags) ? item.tags : []
  var k = item.k || ""

  for (var i = 0; i < terms.length; i++) {
    var term = terms[i]
    var bestTermScore = 0

    // 1. Category check (1.5x priority bonus)
    var catScore = scoreTermAgainstString(cat, term)
    if (catScore > 0) {
      bestTermScore = Math.max(bestTermScore, catScore * 1.5)
    }

    // 2. Tags check (1.2x priority)
    for (var j = 0; j < tags.length; j++) {
      var tagScore = scoreTermAgainstString(tags[j], term)
      if (tagScore > 0) {
        bestTermScore = Math.max(bestTermScore, tagScore * 1.2)
      }
    }

    // 3. Kaomoji literal characters check
    var kScore = scoreTermAgainstString(k, term)
    if (kScore > 0) {
      bestTermScore = Math.max(bestTermScore, kScore)
    }

    // Multi-keyword AND matching: ALL terms must match
    if (bestTermScore === 0) {
      return 0
    }

    totalScore += bestTermScore
  }

  return totalScore
}

function filterKaomoji(list, query, limit) {
  var values = Array.isArray(list) ? list : []
  var rawQuery = String(query || "").trim()
  var max = limit === undefined || limit === null ? 1000 : Number(limit)
  if (isNaN(max)) max = 1000
  max = Math.max(0, max)
  if (max === 0) return []

  if (!rawQuery) {
    return values.slice(0, max)
  }

  var terms = rawQuery.toLowerCase().split(/\s+/).filter(function(t) { return t.length > 0 })
  if (terms.length === 0) {
    return values.slice(0, max)
  }

  var scored = []
  for (var i = 0; i < values.length; i++) {
    var item = values[i]
    if (!item || !item.k) continue
    var score = scoreItem(item, terms)
    if (score > 0) {
      scored.push({ item: item, score: score, index: i })
    }
  }

  // Sort by score descending (higher quality matches first), preserving original order on tie
  scored.sort(function(a, b) {
    if (b.score !== a.score) return b.score - a.score
    return a.index - b.index
  })

  var out = []
  var end = Math.min(scored.length, max)
  for (var s = 0; s < end; s++) {
    out.push(scored[s].item)
  }
  return out
}

if (typeof module !== "undefined") {
  module.exports = {
    parseKaomoji: parseKaomoji,
    filterKaomoji: filterKaomoji,
    isFuzzySubsequence: isFuzzySubsequence,
    scoreTermAgainstString: scoreTermAgainstString,
    scoreItem: scoreItem
  }
}
