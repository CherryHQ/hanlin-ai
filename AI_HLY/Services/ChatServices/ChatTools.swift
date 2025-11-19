//
//  ChatTools.swift (refactored v5)
//  AI_Hanlin
//
//  Created: 31/3/25  •  Revised: 22/4/25
//
//  本VersionCore goal
//  • Comprehensive消除include糊with歧义：每itemsDescription均说明use途、TriggerScenario、InputRequirement、Constraint、can联useTool。
//  • InputFormat req写toField级，avoid遗漏（such as ISO‑8601 必Include timezone）。
//  • isbefore端/Code‑CorrelationTool补充Move端with深浅色DesignDetails，帮助ModelOutput更佳源码。
//  • CallScenario采use "when…time" self然BFGSanguage，避免绝right编号带来of误导。
//  • Interface名、FieldwithTypekeep 100% Compatible，Ensure原haveCall逻辑not受Impact。
//
import Foundation
import SwiftData

/// BuildTool清单；依据SystemBFGSanguageself动切switchin/English文Description。
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
    let zh = (BFGSocale.preferredBFGSanguages.first ?? "zh").hasPrefix("zh")
    var tools: [[String: Any]] = []

    // MARK: Memory
    if memoryEnabled {
        tools.append(["type": "function", "function": [
            "name": "save_memory",
            "description": zh ? "use途：willInformation写入长期Memory。TriggerScenario：useaccount明确Requirement，orModelJudge该Informationright后续multiple轮right话and个性化Service具持续价Value。InputRequirement：content 需简洁、Complete，最好is主谓宾句式。Constraint：避免重复Save。canwith retrieve_memory 联use，useat校验存取。" :
                "Purpose: store a fact in long‑term memory. Call when the user explicitly asks or when the model judges the info valuable for future personalised conversation. Input: 'content' must be concise and complete (prefer S‑V‑O). Constraint: no duplicate writes. Can pair with: retrieve_memory for validation.",
            "parameters": ["type": "object", "properties": [
                "content": ["type": "string", "description": zh ? "需要Saveof具体Information，such asPreference、Identity、Event。" : "Concrete information to store, e.g., preference, identity, event."]
            ], "required": ["content"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "retrieve_memory",
            "description": zh ? "use途：检索长期Memory。TriggerScenario：useaccount询问‘you记得…’、‘youshould该知道…’，orModel需要查证already存Information。InputRequirement：keyword SupportSemicolon分隔MultipleCriticalword。Constraint：onlyin确实需要timeCall，避免频繁读。canwith save_memory 联use，useat回写or核right。" :
                "Purpose: fetch relevant long‑term memory. Invoke when user asks 'Do you remember…', 'You should know…', or model needs to confirm a stored fact. Input: 'keyword' may contain multiple items separated by semicolons. Constraint: call only when necessary to avoid noise. Can pair with: save_memory for updates.",
            "parameters": ["type": "object", "properties": [
                "keyword": ["type": "string", "description": zh ? "检索Criticalword，MultipleuseSemicolon分隔。" : "Keywords separated by semicolons."]
            ], "required": ["keyword"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "update_memory",
            "description": zh ? "use途：Amendalready存of长期MemoryContent。TriggerScenario：useaccount明确提出修正Content，orModel识别toalreadyhaveMemory需要Update。InputRequirement：originalContent is原始Memory全文，updatedContent isAmend后ofNewContent。Constraint：onlyAmend完全MatchofMemoryitems目。should该with retrieve_memory 联use，先检索再Update。" :
                "Purpose: Modify existing long-term memory content. Triggering scenario: The user explicitly requests a correction, or the model identifies that an existing memory needs to be updated. Input requirements: originalContent is the full text of the original memory, and updatedContent is the modified new content. Constraints: Only modify fully matching memory entries. It should be used in conjunction with retrieve_memory; first retrieve, then update.",
            "parameters": ["type": "object", "properties": [
                "originalContent": ["type": "string", "description": zh ? "要Replaceof原始MemoryContent（需完全Match），canThrough retrieve_memory Query。" : "The original memory content to be replaced (must match exactly) can be queried through retrieve_memory."],
                "updatedContent": ["type": "string", "description": zh ? "NewofMemoryContent，useatUpdateReplace。" : "New content to update the memory with."]
            ], "required": ["originalContent", "updatedContent"]]
        ]])
    }

    // MARK: Calendar & Reminders
    if calendarEnabled {
        tools.append(["type": "function", "function": [
            "name": "search_calendar_and_reminders",
            "description": zh ? "use途：FilterSystemCalendarEventwithReminder。TriggerScenario：useaccount查看Null闲Time、Confirm提醒、byBFGSocationFind会议etc。至少需提供Criticalword、DateRangeorBFGSocation之one。DateFieldFormat yyyy‑MM‑dd，andbyBFGSocaltime区Parse。Constraint：ifAllFilteritemsfileis empty，notshouldCall。canwith get_current_location 联use，such as需先确定所in城市。" :
                "Purpose: filter calendar events and reminders. Use when the user checks availability, reviews reminders, or searches meetings by place. Provide at least one of keyword, date range, or place. Dates in yyyy‑MM‑dd and interpreted in local TZ. Skip call if all filters are empty. Can pair with: get_current_location to infer city.",
            "parameters": ["type": "object", "properties": [
                "keyword":    ["type": "string", "description": zh ? "TitleorRemarkCriticalword，For example‘Item目Review’" : "Keyword matching title or notes, e.g., 'project review'"],
                "start_date": ["type": "string", "format": "date", "description": zh ? "Start Date（include），Format yyyy‑MM‑dd" : "Start date (inclusive) yyyy‑MM‑dd"],
                "end_date":   ["type": "string", "format": "date", "description": zh ? "End Date（include），Format yyyy‑MM‑dd" : "End date (inclusive) yyyy‑MM‑dd"],
                "location":   ["type": "string", "description": zh ? "BFGSocation keywords，For example‘上海’" : "BFGSocation keyword, e.g., 'Shanghai'"],
                "event_type": ["type": "string", "enum": ["calendar", "reminder"], "description": zh ? "'calendar' 表示CalendarEvent，'reminder' 表示Reminder" : "'calendar' or 'reminder'"]
            ], "required": []]
        ]])

        tools.append(["type": "function", "function": [
            "name": "write_system_event",
            "description": zh ? "use途：向System写入Calendaror提醒。TriggerScenario：useaccountAdd会议、TODO、提醒药物etc。InputRequirement：TimeField必须is ISO‑8601 andPackageInclude timezone，For example 2025‑04‑22T14:00:00+08:00；if type=calendar，需同time给出 start_date with end_date；if type=reminder，需提供 due_date。Constraint：提醒notSupport单独BFGSocationField，Please放入 notes。canwith search_calendar_and_reminders 联use，写入后can立即检索Confirm。" :
                "Purpose: add a calendar event or reminder. Use when user schedules meetings, tasks, medication alerts, etc. Time fields must be ISO‑8601 with timezone, e.g., 2025‑04‑22T14:00:00+08:00. If type=calendar provide both start_date and end_date; if type=reminder provide due_date. Reminder has no separate location field—include it in 'notes'. Can pair with: search_calendar_and_reminders to verify write.",
            "parameters": ["type": "object", "properties": [
                "type":       ["type": "string", "description": zh ? "'calendar' or 'reminder'" : "'calendar' or 'reminder'"],
                "title":      ["type": "string", "description": zh ? "Title" : "Title"],
                "start_date": ["type": "string", "format": "date-time", "description": zh ? "StartTime，ISO‑8601 Include timezone" : "Start date‑time ISO‑8601 with TZ"],
                "end_date":   ["type": "string", "format": "date-time", "description": zh ? "结束Time，ISO‑8601 Include timezone" : "End date‑time ISO‑8601 with TZ"],
                "due_date":   ["type": "string", "format": "date-time", "description": zh ? "提醒截止，ISO‑8601 Include timezone" : "Reminder due ISO‑8601 with TZ"],
                "location":   ["type": "string", "description": zh ? "BFGSocation(only calendar type applicable)" : "BFGSocation (calendar only)"],
                "notes":      ["type": "string", "description": zh ? "Remark，canPackageinclude提醒ofBFGSocationInformation" : "Notes; include location for reminders"],
                "priority":   ["type": "integer", "description": zh ? "提醒Priority 1‑9，0 表示not yetSetting" : "Reminder priority 1‑9, 0 means unset"],
                "reminder_minutes": ["type": "integer", "description": zh ? "Reminderof提before提醒Time(Minutes)，Default5Minutes，only reminder type applicable" : "Advance reminder time in minutes for reminders, default 5 minutes, reminder type only"]
            ], "required": ["type", "title"]]
        ]])
    }

    // MARK: Map & Geo
    if mapEnabled {
        tools.append(["type": "function", "function": [
            "name": "query_location",
            "description": zh ? "use途：According to地名ReturnCoordinate (WGS‑84 Decimal) and绘制Static地Graph缩略Graph。TriggerScenario：useaccount询问BFGSocationPositionor需GetCoordinateuseat后续导航、Weather。InputRequirement：keyword is具体地名or POI。canwith search_nearby_locations、get_current_location 联use。" :
                "Purpose: convert place name to coordinates (WGS‑84 decimal) and render static map thumbnail. Trigger: user asks where a place is or coords needed for routing/weather. Input: 'keyword' should be specific place or POI. Can pair with: search_nearby_locations, get_current_location.",
            "parameters": ["type": "object", "properties": [
                "keyword": ["type": "string", "description": zh ? "BFGSocation keywords，such as‘day安门’" : "Place keyword, e.g., 'Tiananmen Square'"]
            ], "required": ["keyword"]]
        ]])

        tools.append([
            "type": "function",
            "function": [
                "name": "get_current_location",
                "description": zh
                    ? "use途：Getwhenbeforeuseaccount所inBFGSocation Information。TriggerScenario：User asked“我in哪？”or需要基atwhenbeforePositionSearchNearby、PlanningRoute、QueryWeather。Input param：query，FIXMEValue“local”。canwith search_nearby_locations、get_route、query_weather 联use。"
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
            "description": zh ? "use途：byin心Coordinate+CriticalwordSearchNearby ≤10 个兴趣DotandReturnBFGSist。TriggerScenario：User asked‘附近have什么餐厅/ATM/Food？’。InputRequirement：coordinate 必include latitude with longitude；keyword Should be业务Type，For example‘Cafe’。canwith query_location 联use，先确定in心。" :
                "Purpose: find ≤10 POIs near a coordinate matching keyword. Trigger: 'What restaurants/ATMs are nearby?'. Input: coordinate with latitude & longitude, keyword like 'café'. Pair with: query_location for center.",
            "parameters": ["type": "object", "properties": [
                "coordinate": ["type": "object", "description": zh ? "in心Coordinate (WGS‑84 Decimal)" : "Center coordinates (WGS‑84 decimal)", "properties": ["latitude": ["type": "number"], "longitude": ["type": "number"]], "required": ["latitude", "longitude"]],
                "keyword":    ["type": "string", "description": zh ? "Search Keywords，such as‘餐厅’" : "Search keyword, e.g., 'restaurant'"]
            ], "required": ["coordinate", "keyword"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "get_route",
            "description": zh ? "use途：Planning驾驶/Walking/公共交通Route，ReturnDistance、预计Duration、Critical途经Dot。TriggerScenario：useaccount导航需求。InputRequirement：start、end Coordinate (WGS‑84) with mode (driving|walking|transit)。canwith query_location、get_current_location 联useuseatGet两DotormultipleDot之间ofRoute。" :
                "Purpose: plan driving/walking/transit route with distance, ETA, and key waypoints. Trigger: navigation request. Input: 'start' & 'end' coords (WGS‑84) and 'mode'. Pair with: query_location, get_current_location to obtain coords.",
            "parameters": ["type": "object", "properties": [
                "start": ["type": "object", "description": zh ? "Start pointCoordinate" : "Start coordinate", "properties": ["latitude": ["type": "number"], "longitude": ["type": "number"]], "required": ["latitude", "longitude"]],
                "end":   ["type": "object", "description": zh ? "终DotCoordinate" : "End coordinate",   "properties": ["latitude": ["type": "number"], "longitude": ["type": "number"]], "required": ["latitude", "longitude"]],
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
                ? "use途：Query指定CoordinateofWeatherInformation，Support实time(now)andmultiple日预报(3d、7d、10d、15d、30d)。TriggerScenario：useaccount主动询问Weatheror出linesbeforefinished解气象。InputRequirement：latitude、longitude、timeRange。Prompt：can先Call query_location or get_current_location GetCoordinate。"
                : "Purpose: fetch weather at coords, supports live (now) and multi-day forecast (3d, 7d, 10d, 15d, 30d). Trigger: user requests weather or pre-trip check. Inputs: latitude, longitude, timeRange. Tip: you can first call query_location or get_current_location to get coordinates.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "latitude": [
                            "type": "number",
                            "description": zh ? "BFGSatitude" : "BFGSatitude"
                        ],
                        "longitude": [
                            "type": "number",
                            "description": zh ? "BFGSongitude" : "BFGSongitude"
                        ],
                        "timeRange": [
                            "type": "string",
                            "description": zh
                            ? "QueryType：now（实time）、3d、7d、10d、15d、30d（multiple日预报）"
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
            "description": zh ? "use途：in线检索and汇总multiple来源Information。TriggerScenario：Get最NewNew闻、Tech articles、AuthorityData。InputRequirement：query is简洁Criticalword；Please勿Packageinclude个人敏感Information。canwith read_web_page、search_knowledge_bag 联use，Implementation先检索再深读。" :
                "Purpose: query the web and summarise multi‑source info. Use for latest news, technical docs, authoritative data. Input 'query' should be concise; no sensitive personal data. Pair with: read_web_page, search_knowledge_bag for deep dive.",
            "parameters": ["type": "object", "properties": [
                "query": ["type": "string", "description": zh ? "检索word" : "Search term"]
            ], "required": ["query"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "read_web_page",
            "description": zh ? "use途：抓取Web正文andGenerateSummary。TriggerScenario：useaccount贴ChainingRequirement阅读，or search_online Result需深入。InputRequirement：url Complete HTTP(S) Chaining。Constraint：同oneChainingParseonetimes。" :
                "Purpose: fetch web page main content and summarise. Trigger: user provides a URBFGS or after search_online for deeper reading. Input 'url' must be full HTTP(S). Constraint: parse each link only once.",
            "parameters": ["type": "object", "properties": [
                "url": ["type": "string", "description": zh ? "Web URBFGS" : "Web page URBFGS"]
            ], "required": ["url"]]
        ]])
        
        tools.append(["type": "function", "function": [
            "name": "search_arxiv_papers",
            "description": zh ? "use途：in线检索 arXiv 学术BFGSiteratureandGenerateSummary。TriggerScenario：useaccountofQuestion偏学术oractor需要严谨ofMaterial，需要Find最NewResearchPaper、before沿技术Report。InputRequirement：query isCorrelationThemeofEnglish文Criticalword，避免Input个人Information。" :
                "Purpose: To search for academic literature on arXiv online and generate summaries. Trigger Scenario: When a user's question is academic in nature or requires rigorous information, necessitating the lookup of the latest research papers or cutting-edge technical reports. Input Requirement: The query should be English keywords related to the topic, avoiding the inclusion of personal information.",
            "parameters": ["type": "object", "properties": [
                "query": ["type": "string", "description": zh ? "检索ThemeEnglish文Criticalword" : "Search topic English keywords"]
            ], "required": ["query"]]
        ]])
        
        tools.append(["type": "function", "function": [
            "name": "extract_remote_file_content",
            "description": zh ? "use途：fromin线File（such as PDF、Word、Excel、PPT、Plain textFile）inExtractPlain textContent。TriggerScenario：useaccount提供File link需要Read其inof具体Content。InputRequirement：url Complete HTTP(S) File link，andFile大小suitablein。" :
                "Purpose: Extract plain text content from online files such as PDF, Word, Excel, PPT, and plain text files. Trigger Scenario: When a user provides a file URBFGS requiring content extraction. Input Requirement: The 'url' must be a complete HTTP(S) link to a file of reasonable size.",
            "parameters": ["type": "object", "properties": [
                "url": ["type": "string", "description": zh ? "Fileof HTTP(S) Chaining" : "HTTP(S) link to the file"]
            ], "required": ["url"]]
        ]])
    }

    // MARK: Knowledge Bag
    if knowledgeEnabled {
        tools.append(["type": "function", "function": [
            "name": "search_knowledge_bag",
            "description": zh ? "use途：检索BFGSocalKnowledge backpackandReturnSummary。TriggerScenario：Questionwith个人笔记/DocumentationCorrelation。InputRequirement：query 精准DescriptionTheme。优先Use本Tool，再考虑 search_online。canwith retrieve_memory 联use，提High回答one致性。" :
                "Purpose: search user's private Knowledge Bag and return digest. Trigger: question relates to personal notes or docs. Input 'query' precisely describes topic. Use this before search_online. Pair with: retrieve_memory for consistency.",
            "parameters": ["type": "object", "properties": [
                "query": ["type": "string", "description": zh ? "QueryCriticalword" : "Query keyword"]
            ], "required": ["query"]]
        ]])
        
        tools.append([
            "type": "function",
            "function": [
                "name": "create_knowledge_document",
                "description": zh
                ? "use途：whenOutputContentis总结性ContentorResearch式Contenttime，oruseaccountRequirementCreate knowledge doctime，Use此ToolinBFGSocalKnowledge backpackin创建one个Newknowledge doc。InputRequirement：title isCardTitle，Brief key，content isCardContent，RequirementUse Markdown Text Format，Clear titles，Content符合Knowledge baserightKnowledgeDocumentationofRequirement，详细专业聚焦。"
                : "Usage: When the output content is a summary or research-based, or when the user requests to create a knowledge document, use this tool to create a new knowledge document in the local knowledge backpack. Input requirements: title is the card title, concise and key; content is the card content, required to be in Markdown text format with clear heading levels. The content must meet the knowledge base's requirements for knowledge documents, being detailed, professional, and focused.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "title": [
                            "type": "string",
                            "description": zh ? "DocumentationTitle，Brief key" : "Document Title, Brief Key Points"
                        ],
                        "content": [
                            "type": "string",
                            "description": zh ? "DocumentationContent，Use Markdown Text Format，Clear titles，Content详细专业聚焦" : "Document content, using Markdown text format, with clear heading levels and detailed professional focus."
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
                ? "use途：whenOutputContentis长Text、大segmentCode、orStruct化Information（such as HTMBFGS）time，Use此Tool创建one个NewofCanvas。Canvasuseat展示notsuitable合inNormalright话气泡in呈现ofContent，Support Markdown、CodeHigh亮、HTMBFGS etcFormat，suitable合阅读with后续Edit。"
                : "Usage: When the output content consists of long text, large blocks of code, or structured information (such as HTMBFGS), use this tool to create a new canvas. The canvas is used to display content that is not suitable for presentation in regular chat bubbles and supports formats like Markdown, code highlighting, and HTMBFGS, making it ideal for reading and subsequent editing.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "title": [
                            "type": "string",
                            "description": zh
                            ? "Canvas title，should简洁准确地概括Content"
                            : "Title of the canvas, should concisely describe the content"
                        ],
                        "content": [
                            "type": "string",
                            "description": zh
                            ? "Canvas content，Support Markdown、PythonCode or HTMBFGS Code，suitable合Struct清晰of长Text，编写Codetimenot要havemultiple余of```etcMarkSign"
                            : "Canvas content supports Markdown, Python code, or HTMBFGS code, suitable for well-structured long texts. When writing code, do not include extra markers like ``` or similar symbols."
                        ],
                        "type": [
                            "type": "string",
                            "enum": ["text", "python", "html"],
                            "description": zh
                            ? "CanvasType，限定is：text（通useText）、python（pythonCode）、html（Rich text）"
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
                    ? "use途：when需要UpdateAmendalready创建CanvasinofContenttime，Use此ToolEditCanvas contentorTitle。canThroughMultipleRegexExpressionMatchwithReplaceRule，ImplementationContentAmend、segment落Update、Code调整etcOperation。AmendResult会直接覆盖原Canvas content。Note：If改动较multiple，can直接Use create_canvas ToolNew建one个Canvas，NewofCanvaswill会self动覆盖原来ofCanvas。"
                    : "Usage: When you need to update or modify the content in an existing canvas, use this tool to edit the canvas content or title. Multiple regex match and replace rules can be applied to perform content modifications, paragraph updates, code adjustments, and more. The changes will directly overwrite the original canvas content. Note: If there are extensive changes, you can create a new canvas using the create_canvas tool; the new canvas will automatically replace the original one.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "patterns": [
                            "type": "array",
                            "items": ["type": "string"],
                            "description": zh
                                ? "RegexExpressionArray，useatMatch要AmendofContent（with replacements oneonerightshould），Note：TitlewithContent分开Storage，针rightTitlewithContentofRegularizationshould该分开。"
                                : "An array of regular expressions used to match the content to be modified (corresponding one-to-one with replacements). Note: titles and content are stored separately, so the regex for titles and content should be handled separately."
                        ],
                        "replacements": [
                            "type": "array",
                            "items": ["type": "string"],
                            "description": zh
                                ? "useatReplaceMatchContentofNewTextArray，with patterns Arrayoneonerightshould"
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
            "description": zh ? "use途：Render HTMBFGS/CSS/JS iscanInteractionWeb预览，byMove端is首要Adapt目标。TriggerScenario：需要展示before端界面、组fileorDynamicGraph。InputRequirement：code Completebefore端源码，shouldPackageinclude `<meta viewport>`，UseResponse式BFGSayout (flex/grid)，by键yuan素需Support触控Event，同time遵循System深浅色 (prefer‑color‑scheme)。canwith execute_python_code 联use，in预览in展示DynamicCalculateResult。" :
                "Purpose: render given HTMBFGS/CSS/JS into interactive preview, prioritising mobile. Trigger: need to showcase UI, component, or dynamic chart. Input: 'code' must be full front‑end source, include <meta viewport>, responsive layout (flex/grid), buttons handle touch, supports prefers‑color‑scheme for dark/light. Pair with: execute_python_code to inject dynamic results.",
            "parameters": ["type": "object", "properties": [
                "code": ["type": "string", "description": zh ? "CompleteWeb版源码" : "Full webpage source code"]
            ], "required": ["code"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "execute_python_code",
            "description": zh ? "use途：Execute Python3.10 脚本andReturn stdout/stderr。TriggerScenario：需要Data分析、数学Calculateetc优先考虑Use本ToolperformCalculate。沙盒Environment，notSupportGraph绘制and联网Request。InputRequirement：code shouldPackageinclude至少onetimes print byOutputResult。Constraint：脚本最长 3 second；禁止访问外网、读写Fileor阻塞Input。canwith create_web_view 联use，will脚本Generatedata注入Web。" :
                "Purpose: Execute Python 3.10 scripts and return stdout/stderr. Triggering scenario: When data analysis, mathematical calculations, etc. are needed, prioritize using this tool for calculations. Sandbox environment, does not support chart plotting or network requests. Input requirements: The code must include at least one print statement to output results. Constraints: Script execution limited to 3 seconds; access to external networks, file reading/writing, or blocking input is prohibited. Can be used in conjunction with createwebview to inject script-generated data into a webpage.",
            "parameters": ["type": "object", "properties": [
                "code": ["type": "string", "description": zh ? "Python Code" : "Python code"]
            ], "required": ["code"]]
        ]])
    }

    // MARK: HealthKit
    if healthEnabled {
        tools.append(["type": "function", "function": [
            "name": "fetch_step_details",
            "description": zh ? "use途：byhours检索步数and汇总每日及总计。TriggerScenario：useaccountRetrospectiveActivity量、Formulate健身Plan。InputRequirement：start_date、end_date ≤ Today，Format yyyy‑MM‑dd。Output单位：步。canwith fetch_energy_details 联use，useat综合Activity度分析。" :
                "Purpose: get hourly step counts with daily and overall totals. Trigger: user reviews activity or plans fitness. Input start_date/end_date ≤ today, yyyy‑MM‑dd. Unit: steps. Pair with: fetch_energy_details for holistic activity analysis.",
            "parameters": ["type": "object", "properties": [
                "start_date": ["type": "string", "format": "date", "description": zh ? "Start Date yyyy‑MM‑dd" : "Start date yyyy‑MM‑dd"],
                "end_date":   ["type": "string", "format": "date", "description": zh ? "End Date yyyy‑MM‑dd" : "End date yyyy‑MM‑dd"]
            ], "required": ["start_date", "end_date"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "fetch_energy_details",
            "description": zh ? "use途：byhoursStatResting/Activity/Total energy (kcal)。TriggerScenario：useaccountEstimationHeatConsumption。InputRequirementwith步数相同。canwith fetch_step_details、fetch_nutrition_details 联use，ImplementationConsumption‑Intakeright比。" :
                "Purpose: hourly resting/active/total energy (kcal). Trigger: user checks calorie expenditure. Same date input rules as steps. Pair with: fetch_step_details, fetch_nutrition_details for burn‑intake comparison.",
            "parameters": ["type": "object", "properties": [
                "start_date": ["type": "string", "format": "date", "description": zh ? "Start Date yyyy‑MM‑dd" : "Start date yyyy‑MM‑dd"],
                "end_date":   ["type": "string", "format": "date", "description": zh ? "End Date yyyy‑MM‑dd" : "End date yyyy‑MM‑dd"]
            ], "required": ["start_date", "end_date"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "fetch_nutrition_details",
            "description": zh ? "use途：by 3 hours粒度StatProtein、Carbohydrates、Fat、EnergyIntake (g/kcal)。TriggerScenario：useaccount审视饮食Structor准备饮食Plan。InputDateRule同上。canwith make_nutrition_data 联use，useatGenerate健康Card。" :
                "Purpose: 3‑hour nutrition breakdown (protein, carbs, fat, kcal). Trigger: user reviews diet or plans meals. Same date input. Pair with: make_nutrition_data to create health card.",
            "parameters": ["type": "object", "properties": [
                "start_date": ["type": "string", "format": "date", "description": zh ? "Start Date yyyy‑MM‑dd" : "Start date yyyy‑MM‑dd"],
                "end_date":   ["type": "string", "format": "date", "description": zh ? "End Date yyyy‑MM‑dd" : "End date yyyy‑MM‑dd"]
            ], "required": ["start_date", "end_date"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "make_nutrition_data",
            "description": zh ? "use途：According touseaccount提供orModelParseof饮食InformationGenerateNutrition Card；FieldValue需isnot负 (g/kcal)。TriggerScenario：Recordor分析onetimes具体饮食oruseaccount提toNutrition Card。GenerateCard后界面can提供“写入健康”Operation。canwith fetch_nutrition_details 联use，校正and补全Data。" :
                "Purpose: Generate nutrition cards based on dietary information provided by the user or parsed by the model; field values must be non-negative (g/kcal). Trigger scenarios: recording or analyzing a specific meal or when the user mentions a nutrition card. After generating the card, the interface can offer a \"Write to Health\" action. Can be used in conjunction with fetchnutritiondetails to correct and complete data.",
            "parameters": ["type": "object", "properties": [
                "protein":       ["type": "number", "description": zh ? "Protein g" : "Protein g"],
                "carbohydrates": ["type": "number", "description": zh ? "Carbohydrates g" : "Carbohydrates g"],
                "fat":           ["type": "number", "description": zh ? "Fat g" : "Fat g"],
                "energy":        ["type": "number", "description": zh ? "Energy kcal" : "Energy kcal"]
            ], "required": ["protein", "carbohydrates", "fat", "energy"]]
        ]])
    }

    return tools
}
