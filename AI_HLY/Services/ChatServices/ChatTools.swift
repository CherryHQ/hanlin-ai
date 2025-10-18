//
//  ChatTools.swift (refactored v5)
//  AI_Hanlin
//
//  Created: 31/3/25  •  Revised: 22/4/25
//
//  本版本核心目标
//  • 全面消除含糊与歧义：每条描述均说明用途、触发场景、输入要求、约束、可联用工具。
//  • 输入格式要求写到字段级，避免遗漏（如 ISO‑8601 必含时区）。
//  • 为前端/代码‑相关工具补充移动端与深浅色设计细节，帮助模型输出更佳源码。
//  • 调用场景采用 "当…时" 自然语言，避免绝对编号带来的误导。
//  • 接口名、字段与类型保持 100% 兼容，确保原有调用逻辑不受影响。
//
import Foundation
import SwiftData

/// 构建工具清单；依据系统语言自动切换中/英文描述。
func buildMemoryTools(
    memoryEnabled: Bool = true,
    mapEnabled: Bool = true,
    calendarEnabled: Bool = true,
    searchEnabled: Bool = true,
    knowledgeEnabled: Bool = true,
    codeEnabled: Bool = true,
    healthEnabled: Bool = true,
    weatherEnabled: Bool = true,
    canvasEnabled: Bool = true,
) -> [[String: Any]] {
    let zh = (Locale.preferredLanguages.first ?? "zh").hasPrefix("zh")
    var tools: [[String: Any]] = []

    // MARK: Memory
    if memoryEnabled {
        tools.append(["type": "function", "function": [
            "name": "save_memory",
            "description": zh ? "用途：将信息写入长期记忆。触发场景：用户明确要求，或模型判断该信息对后续多轮对话和个性化服务具持续价值。输入要求：content 需简洁、完整，最好为主谓宾句式。约束：避免重复保存。可与 retrieve_memory 联用，用于校验存取。" :
                "Purpose: store a fact in long‑term memory. Call when the user explicitly asks or when the model judges the info valuable for future personalised conversation. Input: 'content' must be concise and complete (prefer S‑V‑O). Constraint: no duplicate writes. Can pair with: retrieve_memory for validation.",
            "parameters": ["type": "object", "properties": [
                "content": ["type": "string", "description": zh ? "需要保存的具体信息，如偏好、身份、事件。" : "Concrete information to store, e.g., preference, identity, event."]
            ], "required": ["content"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "retrieve_memory",
            "description": zh ? "用途：检索长期记忆。触发场景：用户询问‘你记得…’、‘你应该知道…’，或模型需要查证已存信息。输入要求：keyword 支持分号分隔多个关键词。约束：仅在确实需要时调用，避免频繁读。可与 save_memory 联用，用于回写或核对。" :
                "Purpose: fetch relevant long‑term memory. Invoke when user asks 'Do you remember…', 'You should know…', or model needs to confirm a stored fact. Input: 'keyword' may contain multiple items separated by semicolons. Constraint: call only when necessary to avoid noise. Can pair with: save_memory for updates.",
            "parameters": ["type": "object", "properties": [
                "keyword": ["type": "string", "description": zh ? "检索关键词，多个用分号分隔。" : "Keywords separated by semicolons."]
            ], "required": ["keyword"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "update_memory",
            "description": zh ? "用途：修改已存的长期记忆内容。触发场景：用户明确提出修正内容，或模型识别到已有记忆需要更新。输入要求：originalContent 为原始记忆全文，updatedContent 为修改后的新内容。约束：仅修改完全匹配的记忆条目。应该与 retrieve_memory 联用，先检索再更新。" :
                "Purpose: Modify existing long-term memory content. Triggering scenario: The user explicitly requests a correction, or the model identifies that an existing memory needs to be updated. Input requirements: originalContent is the full text of the original memory, and updatedContent is the modified new content. Constraints: Only modify fully matching memory entries. It should be used in conjunction with retrieve_memory; first retrieve, then update.",
            "parameters": ["type": "object", "properties": [
                "originalContent": ["type": "string", "description": zh ? "要替换的原始记忆内容（需完全匹配），可通过 retrieve_memory 查询。" : "The original memory content to be replaced (must match exactly) can be queried through retrieve_memory."],
                "updatedContent": ["type": "string", "description": zh ? "新的记忆内容，用于更新替换。" : "New content to update the memory with."]
            ], "required": ["originalContent", "updatedContent"]]
        ]])
    }

    // MARK: Calendar & Reminders
    if calendarEnabled {
        tools.append(["type": "function", "function": [
            "name": "search_calendar_and_reminders",
            "description": zh ? "用途：筛选系统日历事件与提醒事项。触发场景：用户查看空闲时间、确认提醒、按地点查找会议等。至少需提供关键词、日期范围或地点之一。日期字段格式 yyyy‑MM‑dd，并以本地时区解析。约束：若所有过滤条件为空，不应调用。可与 get_current_location 联用，如需先确定所在城市。" :
                "Purpose: filter calendar events and reminders. Use when the user checks availability, reviews reminders, or searches meetings by place. Provide at least one of keyword, date range, or place. Dates in yyyy‑MM‑dd and interpreted in local TZ. Skip call if all filters are empty. Can pair with: get_current_location to infer city.",
            "parameters": ["type": "object", "properties": [
                "keyword":    ["type": "string", "description": zh ? "标题或备注关键词，例如‘项目评审’" : "Keyword matching title or notes, e.g., 'project review'"],
                "start_date": ["type": "string", "format": "date", "description": zh ? "开始日期（含），格式 yyyy‑MM‑dd" : "Start date (inclusive) yyyy‑MM‑dd"],
                "end_date":   ["type": "string", "format": "date", "description": zh ? "结束日期（含），格式 yyyy‑MM‑dd" : "End date (inclusive) yyyy‑MM‑dd"],
                "location":   ["type": "string", "description": zh ? "地点关键词，例如‘上海’" : "Location keyword, e.g., 'Shanghai'"],
                "event_type": ["type": "string", "enum": ["calendar", "reminder"], "description": zh ? "'calendar' 表示日历事件，'reminder' 表示提醒事项" : "'calendar' or 'reminder'"]
            ], "required": []]
        ]])

        tools.append(["type": "function", "function": [
            "name": "write_system_event",
            "description": zh ? "用途：向系统写入日历或提醒。触发场景：用户新增会议、待办、提醒药物等。输入要求：时间字段必须为 ISO‑8601 且包含时区，例如 2025‑04‑22T14:00:00+08:00；若 type=calendar，需同时给出 start_date 与 end_date；若 type=reminder，需提供 due_date。约束：提醒不支持单独地点字段，请放入 notes。可与 search_calendar_and_reminders 联用，写入后可立即检索确认。" :
                "Purpose: add a calendar event or reminder. Use when user schedules meetings, tasks, medication alerts, etc. Time fields must be ISO‑8601 with timezone, e.g., 2025‑04‑22T14:00:00+08:00. If type=calendar provide both start_date and end_date; if type=reminder provide due_date. Reminder has no separate location field—include it in 'notes'. Can pair with: search_calendar_and_reminders to verify write.",
            "parameters": ["type": "object", "properties": [
                "type":       ["type": "string", "description": zh ? "'calendar' 或 'reminder'" : "'calendar' or 'reminder'"],
                "title":      ["type": "string", "description": zh ? "标题" : "Title"],
                "start_date": ["type": "string", "format": "date-time", "description": zh ? "开始时间，ISO‑8601 含时区" : "Start date‑time ISO‑8601 with TZ"],
                "end_date":   ["type": "string", "format": "date-time", "description": zh ? "结束时间，ISO‑8601 含时区" : "End date‑time ISO‑8601 with TZ"],
                "due_date":   ["type": "string", "format": "date-time", "description": zh ? "提醒截止，ISO‑8601 含时区" : "Reminder due ISO‑8601 with TZ"],
                "location":   ["type": "string", "description": zh ? "地点(仅 calendar 类型适用)" : "Location (calendar only)"],
                "notes":      ["type": "string", "description": zh ? "备注，可包含提醒的地点信息" : "Notes; include location for reminders"],
                "priority":   ["type": "integer", "description": zh ? "提醒优先级 1‑9，0 表示未设置" : "Reminder priority 1‑9, 0 means unset"],
                "reminder_minutes": ["type": "integer", "description": zh ? "提醒事项的提前提醒时间(分钟)，默认5分钟，仅 reminder 类型适用" : "Advance reminder time in minutes for reminders, default 5 minutes, reminder type only"]
            ], "required": ["type", "title"]]
        ]])
    }

    // MARK: Map & Geo
    if mapEnabled {
        tools.append(["type": "function", "function": [
            "name": "query_location",
            "description": zh ? "用途：根据地名返回坐标 (WGS‑84 十进制度) 并绘制静态地图缩略图。触发场景：用户询问地点位置或需获取坐标用于后续导航、天气。输入要求：keyword 为具体地名或 POI。可与 search_nearby_locations、get_current_location 联用。" :
                "Purpose: convert place name to coordinates (WGS‑84 decimal) and render static map thumbnail. Trigger: user asks where a place is or coords needed for routing/weather. Input: 'keyword' should be specific place or POI. Can pair with: search_nearby_locations, get_current_location.",
            "parameters": ["type": "object", "properties": [
                "keyword": ["type": "string", "description": zh ? "地点关键词，如‘天安门’" : "Place keyword, e.g., 'Tiananmen Square'"]
            ], "required": ["keyword"]]
        ]])

        tools.append([
            "type": "function",
            "function": [
                "name": "get_current_location",
                "description": zh
                    ? "用途：获取当前用户所在位置信息。触发场景：用户问“我在哪？”或需要基于当前位置搜索周边、规划路线、查询天气。输入参数：query，固定值“local”。可与 search_nearby_locations、get_route、query_weather 联用。"
                    : "Purpose: To obtain the current location information of the user. Trigger scenario: When the user asks \"Where am I?\" or needs to search nearby places or plan a route based on the current location. Input parameter: query, fixed value \"local\". Can be used in conjunction with search_nearby_locations, get_route, query_weather.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "query": [
                            "type": "string",
                            "enum": ["local"]
                        ]
                    ],
                    "required": ["query"]
                ]
            ]
        ])

        tools.append(["type": "function", "function": [
            "name": "search_nearby_locations",
            "description": zh ? "用途：按中心坐标+关键词搜索周边 ≤10 个兴趣点并返回列表。触发场景：用户问‘附近有什么餐厅/ATM/美食？’。输入要求：coordinate 必含 latitude 与 longitude；keyword 应为业务类型，例如‘咖啡馆’。可与 query_location 联用，先确定中心。" :
                "Purpose: find ≤10 POIs near a coordinate matching keyword. Trigger: 'What restaurants/ATMs are nearby?'. Input: coordinate with latitude & longitude, keyword like 'café'. Pair with: query_location for center.",
            "parameters": ["type": "object", "properties": [
                "coordinate": ["type": "object", "description": zh ? "中心坐标 (WGS‑84 十进制度)" : "Center coordinates (WGS‑84 decimal)", "properties": ["latitude": ["type": "number"], "longitude": ["type": "number"]], "required": ["latitude", "longitude"]],
                "keyword":    ["type": "string", "description": zh ? "搜索关键词，如‘餐厅’" : "Search keyword, e.g., 'restaurant'"]
            ], "required": ["coordinate", "keyword"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "get_route",
            "description": zh ? "用途：规划驾驶/步行/公共交通路线，返回距离、预计时长、关键途经点。触发场景：用户导航需求。输入要求：start、end 坐标 (WGS‑84) 与 mode (driving|walking|transit)。可与 query_location、get_current_location 联用用于获取两点或多点之间的路线。" :
                "Purpose: plan driving/walking/transit route with distance, ETA, and key waypoints. Trigger: navigation request. Input: 'start' & 'end' coords (WGS‑84) and 'mode'. Pair with: query_location, get_current_location to obtain coords.",
            "parameters": ["type": "object", "properties": [
                "start": ["type": "object", "description": zh ? "起点坐标" : "Start coordinate", "properties": ["latitude": ["type": "number"], "longitude": ["type": "number"]], "required": ["latitude", "longitude"]],
                "end":   ["type": "object", "description": zh ? "终点坐标" : "End coordinate",   "properties": ["latitude": ["type": "number"], "longitude": ["type": "number"]], "required": ["latitude", "longitude"]],
                "mode":  ["type": "string", "enum": ["driving", "walking", "transit"], "description": zh ? "交通方式" : "Transport mode"]
            ], "required": ["start", "end", "mode"]]
        ]])
    }
    
    // MARK: Weather
    if weatherEnabled {
        tools.append([
            "type": "function",
            "function": [
                "name": "query_weather",
                "description": zh
                ? "用途：查询指定坐标的天气信息，支持实时(now)和多日预报(3d、7d、10d、15d、30d)。触发场景：用户主动询问天气或出行前了解气象。输入要求：latitude、longitude、timeRange。提示：可先调用 query_location 或 get_current_location 获取坐标。"
                : "Purpose: fetch weather at coords, supports live (now) and multi-day forecast (3d, 7d, 10d, 15d, 30d). Trigger: user requests weather or pre-trip check. Inputs: latitude, longitude, timeRange. Tip: you can first call query_location or get_current_location to get coordinates.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "latitude": [
                            "type": "number",
                            "description": zh ? "纬度" : "Latitude"
                        ],
                        "longitude": [
                            "type": "number",
                            "description": zh ? "经度" : "Longitude"
                        ],
                        "timeRange": [
                            "type": "string",
                            "description": zh
                            ? "查询类型：now（实时）、3d、7d、10d、15d、30d（多日预报）"
                            : "Time range: now (current), 3d, 7d, 10d, 15d, 30d (multi-day forecast)"
                        ]
                    ],
                    "required": ["latitude", "longitude", "timeRange"]
                ]
            ]
        ])
    }

    // MARK: Online Search & Web
    if searchEnabled {
        tools.append(["type": "function", "function": [
            "name": "search_online",
            "description": zh ? "用途：在线检索并汇总多来源信息。触发场景：获取最新新闻、技术文章、权威数据。输入要求：query 为简洁关键词；请勿包含个人敏感信息。可与 read_web_page、search_knowledge_bag 联用，实现先检索再深读。" :
                "Purpose: query the web and summarise multi‑source info. Use for latest news, technical docs, authoritative data. Input 'query' should be concise; no sensitive personal data. Pair with: read_web_page, search_knowledge_bag for deep dive.",
            "parameters": ["type": "object", "properties": [
                "query": ["type": "string", "description": zh ? "检索词" : "Search term"]
            ], "required": ["query"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "read_web_page",
            "description": zh ? "用途：抓取网页正文并生成摘要。触发场景：用户贴链接要求阅读，或 search_online 结果需深入。输入要求：url 为完整 HTTP(S) 链接。约束：同一链接解析一次。" :
                "Purpose: fetch web page main content and summarise. Trigger: user provides a URL or after search_online for deeper reading. Input 'url' must be full HTTP(S). Constraint: parse each link only once.",
            "parameters": ["type": "object", "properties": [
                "url": ["type": "string", "description": zh ? "网页 URL" : "Web page URL"]
            ], "required": ["url"]]
        ]])
        
        tools.append(["type": "function", "function": [
            "name": "search_arxiv_papers",
            "description": zh ? "用途：在线检索 arXiv 学术文献并生成摘要。触发场景：用户的问题偏学术或者需要严谨的资料，需要查找最新研究论文、前沿技术报告。输入要求：query 为相关主题的英文关键词，避免输入个人信息。" :
                "Purpose: To search for academic literature on arXiv online and generate summaries. Trigger Scenario: When a user's question is academic in nature or requires rigorous information, necessitating the lookup of the latest research papers or cutting-edge technical reports. Input Requirement: The query should be English keywords related to the topic, avoiding the inclusion of personal information.",
            "parameters": ["type": "object", "properties": [
                "query": ["type": "string", "description": zh ? "检索主题英文关键词" : "Search topic English keywords"]
            ], "required": ["query"]]
        ]])
        
        tools.append(["type": "function", "function": [
            "name": "extract_remote_file_content",
            "description": zh ? "用途：从在线文件（如 PDF、Word、Excel、PPT、纯文本文件）中提取纯文本内容。触发场景：用户提供文件链接需要读取其中的具体内容。输入要求：url 为完整 HTTP(S) 文件链接，且文件大小适中。" :
                "Purpose: Extract plain text content from online files such as PDF, Word, Excel, PPT, and plain text files. Trigger Scenario: When a user provides a file URL requiring content extraction. Input Requirement: The 'url' must be a complete HTTP(S) link to a file of reasonable size.",
            "parameters": ["type": "object", "properties": [
                "url": ["type": "string", "description": zh ? "文件的 HTTP(S) 链接" : "HTTP(S) link to the file"]
            ], "required": ["url"]]
        ]])
    }

    // MARK: Knowledge Bag
    if knowledgeEnabled {
        tools.append(["type": "function", "function": [
            "name": "search_knowledge_bag",
            "description": zh ? "用途：检索本地知识背包并返回摘要。触发场景：问题与个人笔记/文档相关。输入要求：query 精准描述主题。优先使用本工具，再考虑 search_online。可与 retrieve_memory 联用，提高回答一致性。" :
                "Purpose: search user's private Knowledge Bag and return digest. Trigger: question relates to personal notes or docs. Input 'query' precisely describes topic. Use this before search_online. Pair with: retrieve_memory for consistency.",
            "parameters": ["type": "object", "properties": [
                "query": ["type": "string", "description": zh ? "查询关键词" : "Query keyword"]
            ], "required": ["query"]]
        ]])
        
        tools.append([
            "type": "function",
            "function": [
                "name": "create_knowledge_document",
                "description": zh
                ? "用途：当输出内容为总结性内容或调研式内容时，或用户要求创建知识文档时，使用此工具在本地知识背包中创建一个新的知识文档。输入要求：title 为卡片标题，简短关键，content 为卡片内容，要求使用 Markdown 文本格式，有清晰的标题等级，内容符合知识库对知识文档的要求，详细专业聚焦。"
                : "Usage: When the output content is a summary or research-based, or when the user requests to create a knowledge document, use this tool to create a new knowledge document in the local knowledge backpack. Input requirements: title is the card title, concise and key; content is the card content, required to be in Markdown text format with clear heading levels. The content must meet the knowledge base's requirements for knowledge documents, being detailed, professional, and focused.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "title": [
                            "type": "string",
                            "description": zh ? "文档标题，简短关键" : "Document Title, Brief Key Points"
                        ],
                        "content": [
                            "type": "string",
                            "description": zh ? "文档内容，使用 Markdown 文本格式，有清晰的标题等级，内容详细专业聚焦" : "Document content, using Markdown text format, with clear heading levels and detailed professional focus."
                        ]
                    ],
                    "required": ["title", "content"]
                ]
            ]
        ])
    }
    
    // MARK: Canvas
    if canvasEnabled {
        tools.append([
            "type": "function",
            "function": [
                "name": "create_canvas",
                "description": zh
                ? "用途：当输出内容为长文本、大段代码、或结构化信息（如 HTML）时，使用此工具创建一个新的画布。画布用于展示不适合在普通对话气泡中呈现的内容，支持 Markdown、代码高亮、HTML 等格式，适合阅读与后续编辑。"
                : "Usage: When the output content consists of long text, large blocks of code, or structured information (such as HTML), use this tool to create a new canvas. The canvas is used to display content that is not suitable for presentation in regular chat bubbles and supports formats like Markdown, code highlighting, and HTML, making it ideal for reading and subsequent editing.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "title": [
                            "type": "string",
                            "description": zh
                            ? "画布标题，应简洁准确地概括内容"
                            : "Title of the canvas, should concisely describe the content"
                        ],
                        "content": [
                            "type": "string",
                            "description": zh
                            ? "画布内容，支持 Markdown、Python代码 或 HTML 代码，适合结构清晰的长文本，编写代码时不要有多余的```等标记符号"
                            : "Canvas content supports Markdown, Python code, or HTML code, suitable for well-structured long texts. When writing code, do not include extra markers like ``` or similar symbols."
                        ],
                        "type": [
                            "type": "string",
                            "enum": ["text", "python", "html"],
                            "description": zh
                            ? "画布类型，限定为：text（通用文本）、python（python代码）、html（富文本）"
                            : "Canvas type, restricted to: text (general text), python (code), html (rich text)"
                        ]
                    ],
                    "required": ["title", "content", "type"]
                ]
            ]
        ])
        
        tools.append([
            "type": "function",
            "function": [
                "name": "edit_canvas",
                "description": zh
                    ? "用途：当需要更新修改已创建画布中的内容时，使用此工具编辑画布内容或标题。可通过多个正则表达式匹配与替换规则，实现内容修改、段落更新、代码调整等操作。修改结果会直接覆盖原画布内容。注意：如果改动较多，可直接使用 create_canvas 工具新建一个画布，新的画布将会自动覆盖原来的画布。"
                    : "Usage: When you need to update or modify the content in an existing canvas, use this tool to edit the canvas content or title. Multiple regex match and replace rules can be applied to perform content modifications, paragraph updates, code adjustments, and more. The changes will directly overwrite the original canvas content. Note: If there are extensive changes, you can create a new canvas using the create_canvas tool; the new canvas will automatically replace the original one.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "patterns": [
                            "type": "array",
                            "items": ["type": "string"],
                            "description": zh
                                ? "正则表达式数组，用于匹配要修改的内容（与 replacements 一一对应），注意：标题与内容分开存储，针对标题与内容的正则化应该分开。"
                                : "An array of regular expressions used to match the content to be modified (corresponding one-to-one with replacements). Note: titles and content are stored separately, so the regex for titles and content should be handled separately."
                        ],
                        "replacements": [
                            "type": "array",
                            "items": ["type": "string"],
                            "description": zh
                                ? "用于替换匹配内容的新文本数组，与 patterns 数组一一对应"
                                : "Array of replacement strings, one-to-one aligned with patterns"
                        ]
                    ],
                    "required": ["patterns", "replacements"]
                ]
            ]
        ])
    }

    // MARK: Code & WebView
    if codeEnabled {
        tools.append(["type": "function", "function": [
            "name": "create_web_view",
            "description": zh ? "用途：渲染 HTML/CSS/JS 为可交互网页预览，以移动端为首要适配目标。触发场景：需要展示前端界面、组件或动态图表。输入要求：code 为完整前端源码，应包含 `<meta viewport>`，使用响应式布局 (flex/grid)，按键元素需支持触控事件，同时遵循系统深浅色 (prefer‑color‑scheme)。可与 execute_python_code 联用，在预览中展示动态计算结果。" :
                "Purpose: render given HTML/CSS/JS into interactive preview, prioritising mobile. Trigger: need to showcase UI, component, or dynamic chart. Input: 'code' must be full front‑end source, include <meta viewport>, responsive layout (flex/grid), buttons handle touch, supports prefers‑color‑scheme for dark/light. Pair with: execute_python_code to inject dynamic results.",
            "parameters": ["type": "object", "properties": [
                "code": ["type": "string", "description": zh ? "完整网页版源码" : "Full webpage source code"]
            ], "required": ["code"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "execute_python_code",
            "description": zh ? "用途：执行 Python3.10 脚本并返回 stdout/stderr。触发场景：需要数据分析、数学计算等优先考虑使用本工具进行计算。沙盒环境，不支持图表绘制和联网请求。输入要求：code 应包含至少一次 print 以输出结果。约束：脚本最长 3 秒；禁止访问外网、读写文件或阻塞输入。可与 create_web_view 联用，将脚本生成的数据注入网页。" :
                "Purpose: Execute Python 3.10 scripts and return stdout/stderr. Triggering scenario: When data analysis, mathematical calculations, etc. are needed, prioritize using this tool for calculations. Sandbox environment, does not support chart plotting or network requests. Input requirements: The code must include at least one print statement to output results. Constraints: Script execution limited to 3 seconds; access to external networks, file reading/writing, or blocking input is prohibited. Can be used in conjunction with createwebview to inject script-generated data into a webpage.",
            "parameters": ["type": "object", "properties": [
                "code": ["type": "string", "description": zh ? "Python 代码" : "Python code"]
            ], "required": ["code"]]
        ]])
    }

    // MARK: HealthKit
    if healthEnabled {
        tools.append(["type": "function", "function": [
            "name": "fetch_step_details",
            "description": zh ? "用途：按小时检索步数并汇总每日及总计。触发场景：用户回顾活动量、制定健身计划。输入要求：start_date、end_date ≤ 今天，格式 yyyy‑MM‑dd。输出单位：步。可与 fetch_energy_details 联用，用于综合活动度分析。" :
                "Purpose: get hourly step counts with daily and overall totals. Trigger: user reviews activity or plans fitness. Input start_date/end_date ≤ today, yyyy‑MM‑dd. Unit: steps. Pair with: fetch_energy_details for holistic activity analysis.",
            "parameters": ["type": "object", "properties": [
                "start_date": ["type": "string", "format": "date", "description": zh ? "开始日期 yyyy‑MM‑dd" : "Start date yyyy‑MM‑dd"],
                "end_date":   ["type": "string", "format": "date", "description": zh ? "结束日期 yyyy‑MM‑dd" : "End date yyyy‑MM‑dd"]
            ], "required": ["start_date", "end_date"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "fetch_energy_details",
            "description": zh ? "用途：按小时统计静息/活动/总能量 (kcal)。触发场景：用户评估热量消耗。输入要求与步数相同。可与 fetch_step_details、fetch_nutrition_details 联用，实现消耗‑摄入对比。" :
                "Purpose: hourly resting/active/total energy (kcal). Trigger: user checks calorie expenditure. Same date input rules as steps. Pair with: fetch_step_details, fetch_nutrition_details for burn‑intake comparison.",
            "parameters": ["type": "object", "properties": [
                "start_date": ["type": "string", "format": "date", "description": zh ? "开始日期 yyyy‑MM‑dd" : "Start date yyyy‑MM‑dd"],
                "end_date":   ["type": "string", "format": "date", "description": zh ? "结束日期 yyyy‑MM‑dd" : "End date yyyy‑MM‑dd"]
            ], "required": ["start_date", "end_date"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "fetch_nutrition_details",
            "description": zh ? "用途：以 3 小时粒度统计蛋白质、碳水、脂肪、能量摄入 (g/kcal)。触发场景：用户审视饮食结构或准备饮食计划。输入日期规则同上。可与 make_nutrition_data 联用，用于生成健康卡片。" :
                "Purpose: 3‑hour nutrition breakdown (protein, carbs, fat, kcal). Trigger: user reviews diet or plans meals. Same date input. Pair with: make_nutrition_data to create health card.",
            "parameters": ["type": "object", "properties": [
                "start_date": ["type": "string", "format": "date", "description": zh ? "开始日期 yyyy‑MM‑dd" : "Start date yyyy‑MM‑dd"],
                "end_date":   ["type": "string", "format": "date", "description": zh ? "结束日期 yyyy‑MM‑dd" : "End date yyyy‑MM‑dd"]
            ], "required": ["start_date", "end_date"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "make_nutrition_data",
            "description": zh ? "用途：根据用户提供或模型解析的饮食信息生成营养卡片；字段值需为非负 (g/kcal)。触发场景：记录或分析一次具体饮食或用户提到营养卡片。生成卡片后界面可提供“写入健康”操作。可与 fetch_nutrition_details 联用，校正和补全数据。" :
                "Purpose: Generate nutrition cards based on dietary information provided by the user or parsed by the model; field values must be non-negative (g/kcal). Trigger scenarios: recording or analyzing a specific meal or when the user mentions a nutrition card. After generating the card, the interface can offer a \"Write to Health\" action. Can be used in conjunction with fetchnutritiondetails to correct and complete data.",
            "parameters": ["type": "object", "properties": [
                "protein":       ["type": "number", "description": zh ? "蛋白质 g" : "Protein g"],
                "carbohydrates": ["type": "number", "description": zh ? "碳水化合物 g" : "Carbohydrates g"],
                "fat":           ["type": "number", "description": zh ? "脂肪 g" : "Fat g"],
                "energy":        ["type": "number", "description": zh ? "能量 kcal" : "Energy kcal"]
            ], "required": ["protein", "carbohydrates", "fat", "energy"]]
        ]])
    }

    return tools
}
