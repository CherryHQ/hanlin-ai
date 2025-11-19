//
//  ChatTools.swift (refactored v5)
//  AI_Hanlin
//
//  Created: 31/3/25  •  Revised: 22/4/25
//
//  thisVersionCore goal
//  • Comprehensive消removeinclude糊with歧义：eachitemsDescriptionequalillustrationuseway、TriggerScenario、InputRequirement、Constraint、cancoupletsuseTool。
//  • InputFormat reqwritetoField级，avoid遗漏（such as ISO‑8601 必Include timezone）。
//  • isbeforeterminal/Code‑CorrelationToolsupplementMoveterminalwith深浅色DesignDetails，帮助ModelOutputmore佳source code。
//  • CallScenario采use "when…time" self然BFGSanguage，avoidabsoluteright编号carrycomeof误导。
//  • Interfacename、FieldwithTypekeep 100% Compatible，EnsureoriginalhaveCalllogicnot受Impact。
//
import Foundation
import SwiftData

/// BuildToolclearsingle；依据SystemBFGSanguageselfdynamiccutswitchin/EnglishtextDescription。
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
            "description": zh ? "useway：willInformationwritelong期Memory。TriggerScenario：useaccountclearRequirement，orModelJudgethatInformationrightaftercontinuemultipleroundrightwordandpersonalizedService具持continue价Value。InputRequirement：content needconcise、Complete，most好ismain谓宾sentencestyle。Constraint：avoidrepeatSave。canwith retrieve_memory coupletsuse，useatvalidatestoretake。" :
                "Purpose: store a fact in long‑term memory. Call when the user explicitly asks or when the model judges the info valuable for future personalised conversation. Input: 'content' must be concise and complete (prefer S‑V‑O). Constraint: no duplicate writes. Can pair with: retrieve_memory for validation.",
            "parameters": ["type": "object", "properties": [
                "content": ["type": "string", "description": zh ? "needSaveofconcreteInformation，such asPreference、Identity、Event。" : "Concrete information to store, e.g., preference, identity, event."]
            ], "required": ["content"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "retrieve_memory",
            "description": zh ? "useway：retrievelong期Memory。TriggerScenario：useaccount询问‘you记得…’、‘youshouldthat知道…’，orModelneed查证alreadystoreInformation。InputRequirement：keyword SupportSemicolonseparateMultipleCriticalword。Constraint：onlyinconfirmrealneedtimeCall，avoid频繁读。canwith save_memory coupletsuse，useat回writeor核right。" :
                "Purpose: fetch relevant long‑term memory. Invoke when user asks 'Do you remember…', 'You should know…', or model needs to confirm a stored fact. Input: 'keyword' may contain multiple items separated by semicolons. Constraint: call only when necessary to avoid noise. Can pair with: save_memory for updates.",
            "parameters": ["type": "object", "properties": [
                "keyword": ["type": "string", "description": zh ? "retrieveCriticalword，MultipleuseSemicolonseparate。" : "Keywords separated by semicolons."]
            ], "required": ["keyword"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "update_memory",
            "description": zh ? "useway：Amendalreadystoreoflong期MemoryContent。TriggerScenario：useaccountclearmentionout修正Content，orModelrecognizetoalreadyhaveMemoryneedUpdate。InputRequirement：originalContent isoriginalstartMemorywholetext，updatedContent isAmendafterofNewContent。Constraint：onlyAmend完wholeMatchofMemoryitemsitem。shouldthatwith retrieve_memory coupletsuse，firstretrieveagainUpdate。" :
                "Purpose: Modify existing long-term memory content. Triggering scenario: The user explicitly requests a correction, or the model identifies that an existing memory needs to be updated. Input requirements: originalContent is the full text of the original memory, and updatedContent is the modified new content. Constraints: Only modify fully matching memory entries. It should be used in conjunction with retrieve_memory; first retrieve, then update.",
            "parameters": ["type": "object", "properties": [
                "originalContent": ["type": "string", "description": zh ? "needReplaceoforiginalstartMemoryContent（need完wholeMatch），canThrough retrieve_memory Query。" : "The original memory content to be replaced (must match exactly) can be queried through retrieve_memory."],
                "updatedContent": ["type": "string", "description": zh ? "NewofMemoryContent，useatUpdateReplace。" : "New content to update the memory with."]
            ], "required": ["originalContent", "updatedContent"]]
        ]])
    }

    // MARK: Calendar & Reminders
    if calendarEnabled {
        tools.append(["type": "function", "function": [
            "name": "search_calendar_and_reminders",
            "description": zh ? "useway：FilterSystemCalendarEventwithReminder。TriggerScenario：useaccountviewNull闲Time、Confirmreminder、byBFGSocationFindcan议etc。至少needprovideCriticalword、DateRangeorBFGSocationofone。DateFieldFormat yyyy‑MM‑dd，andbyBFGSocaltimeareaParse。Constraint：ifAllFilteritemsfileis empty，notshouldCall。canwith get_current_location coupletsuse，such asneedfirstconfirmfixedplacein城市。" :
                "Purpose: filter calendar events and reminders. Use when the user checks availability, reviews reminders, or searches meetings by place. Provide at least one of keyword, date range, or place. Dates in yyyy‑MM‑dd and interpreted in local TZ. Skip call if all filters are empty. Can pair with: get_current_location to infer city.",
            "parameters": ["type": "object", "properties": [
                "keyword":    ["type": "string", "description": zh ? "TitleorRemarkCriticalword，For example‘ItemitemReview’" : "Keyword matching title or notes, e.g., 'project review'"],
                "start_date": ["type": "string", "format": "date", "description": zh ? "Start Date（include），Format yyyy‑MM‑dd" : "Start date (inclusive) yyyy‑MM‑dd"],
                "end_date":   ["type": "string", "format": "date", "description": zh ? "End Date（include），Format yyyy‑MM‑dd" : "End date (inclusive) yyyy‑MM‑dd"],
                "location":   ["type": "string", "description": zh ? "BFGSocation keywords，For example‘up海’" : "BFGSocation keyword, e.g., 'Shanghai'"],
                "event_type": ["type": "string", "enum": ["calendar", "reminder"], "description": zh ? "'calendar' indicateCalendarEvent，'reminder' indicateReminder" : "'calendar' or 'reminder'"]
            ], "required": []]
        ]])

        tools.append(["type": "function", "function": [
            "name": "write_system_event",
            "description": zh ? "useway：directionSystemwriteCalendarorreminder。TriggerScenario：useaccountAddcan议、TODO、reminder药物etc。InputRequirement：TimeField必须is ISO‑8601 andPackageInclude timezone，For example 2025‑04‑22T14:00:00+08:00；if type=calendar，needsametimeprovide start_date with end_date；if type=reminder，needprovide due_date。Constraint：remindernotSupportsingle独BFGSocationField，Please放入 notes。canwith search_calendar_and_reminders coupletsuse，writeaftercan立that isretrieveConfirm。" :
                "Purpose: add a calendar event or reminder. Use when user schedules meetings, tasks, medication alerts, etc. Time fields must be ISO‑8601 with timezone, e.g., 2025‑04‑22T14:00:00+08:00. If type=calendar provide both start_date and end_date; if type=reminder provide due_date. Reminder has no separate location field—include it in 'notes'. Can pair with: search_calendar_and_reminders to verify write.",
            "parameters": ["type": "object", "properties": [
                "type":       ["type": "string", "description": zh ? "'calendar' or 'reminder'" : "'calendar' or 'reminder'"],
                "title":      ["type": "string", "description": zh ? "Title" : "Title"],
                "start_date": ["type": "string", "format": "date-time", "description": zh ? "StartTime，ISO‑8601 Include timezone" : "Start date‑time ISO‑8601 with TZ"],
                "end_date":   ["type": "string", "format": "date-time", "description": zh ? "endTime，ISO‑8601 Include timezone" : "End date‑time ISO‑8601 with TZ"],
                "due_date":   ["type": "string", "format": "date-time", "description": zh ? "reminder截止，ISO‑8601 Include timezone" : "Reminder due ISO‑8601 with TZ"],
                "location":   ["type": "string", "description": zh ? "BFGSocation(only calendar type applicable)" : "BFGSocation (calendar only)"],
                "notes":      ["type": "string", "description": zh ? "Remark，canPackageincludereminderofBFGSocationInformation" : "Notes; include location for reminders"],
                "priority":   ["type": "integer", "description": zh ? "reminderPriority 1‑9，0 indicatenot yetSetting" : "Reminder priority 1‑9, 0 means unset"],
                "reminder_minutes": ["type": "integer", "description": zh ? "ReminderofmentionbeforereminderTime(Minutes)，Default5Minutes，only reminder type applicable" : "Advance reminder time in minutes for reminders, default 5 minutes, reminder type only"]
            ], "required": ["type", "title"]]
        ]])
    }

    // MARK: Map & Geo
    if mapEnabled {
        tools.append(["type": "function", "function": [
            "name": "query_location",
            "description": zh ? "useway：According toplacenameReturnCoordinate (WGS‑84 Decimal) and绘制StaticplaceGraph缩略Graph。TriggerScenario：useaccount询问BFGSocationPositionorneedGetCoordinateuseataftercontinuenavigation、Weather。InputRequirement：keyword isconcreteplacenameor POI。canwith search_nearby_locations、get_current_location coupletsuse。" :
                "Purpose: convert place name to coordinates (WGS‑84 decimal) and render static map thumbnail. Trigger: user asks where a place is or coords needed for routing/weather. Input: 'keyword' should be specific place or POI. Can pair with: search_nearby_locations, get_current_location.",
            "parameters": ["type": "object", "properties": [
                "keyword": ["type": "string", "description": zh ? "BFGSocation keywords，such as‘dayinstall门’" : "Place keyword, e.g., 'Tiananmen Square'"]
            ], "required": ["keyword"]]
        ]])

        tools.append([
            "type": "function",
            "function": [
                "name": "get_current_location",
                "description": zh
                    ? "useway：GetwhenbeforeuseaccountplaceinBFGSocation Information。TriggerScenario：User asked“Iin哪？”orneedbaseatwhenbeforePositionSearchNearby、PlanningRoute、QueryWeather。Input param：query，FIXMEValue“local”。canwith search_nearby_locations、get_route、query_weather coupletsuse。"
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
            "description": zh ? "useway：byinheartCoordinate+CriticalwordSearchNearby ≤10 个兴趣DotandReturnBFGSist。TriggerScenario：User asked‘nearbyhave什么餐厅/ATM/Food？’。InputRequirement：coordinate 必include latitude with longitude；keyword Should be业务Type，For example‘Cafe’。canwith query_location coupletsuse，firstconfirmfixedinheart。" :
                "Purpose: find ≤10 POIs near a coordinate matching keyword. Trigger: 'What restaurants/ATMs are nearby?'. Input: coordinate with latitude & longitude, keyword like 'café'. Pair with: query_location for center.",
            "parameters": ["type": "object", "properties": [
                "coordinate": ["type": "object", "description": zh ? "inheartCoordinate (WGS‑84 Decimal)" : "Center coordinates (WGS‑84 decimal)", "properties": ["latitude": ["type": "number"], "longitude": ["type": "number"]], "required": ["latitude", "longitude"]],
                "keyword":    ["type": "string", "description": zh ? "Search Keywords，such as‘餐厅’" : "Search keyword, e.g., 'restaurant'"]
            ], "required": ["coordinate", "keyword"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "get_route",
            "description": zh ? "useway：Planning驾驶/Walking/publictrafficRoute，ReturnDistance、preplanDuration、CriticalwaythroughDot。TriggerScenario：useaccountnavigationneedrequest。InputRequirement：start、end Coordinate (WGS‑84) with mode (driving|walking|transit)。canwith query_location、get_current_location coupletsuseuseatGettwoDotormultipleDotofbetweenofRoute。" :
                "Purpose: plan driving/walking/transit route with distance, ETA, and key waypoints. Trigger: navigation request. Input: 'start' & 'end' coords (WGS‑84) and 'mode'. Pair with: query_location, get_current_location to obtain coords.",
            "parameters": ["type": "object", "properties": [
                "start": ["type": "object", "description": zh ? "Start pointCoordinate" : "Start coordinate", "properties": ["latitude": ["type": "number"], "longitude": ["type": "number"]], "required": ["latitude", "longitude"]],
                "end":   ["type": "object", "description": zh ? "endDotCoordinate" : "End coordinate",   "properties": ["latitude": ["type": "number"], "longitude": ["type": "number"]], "required": ["latitude", "longitude"]],
                "mode":  ["type": "string", "enum": ["driving", "walking", "transit"], "description": zh ? "trafficsquarestyle" : "Transport mode"]
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
                ? "useway：QueryspecifyCoordinateofWeatherInformation，Supportrealtime(now)andmultipleweather forecast(3d、7d、10d、15d、30d)。TriggerScenario：useaccountmaindynamic询问Weatheroroutlinesbeforefinished解气象。InputRequirement：latitude、longitude、timeRange。Prompt：canfirstCall query_location or get_current_location GetCoordinate。"
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
                            ? "QueryType：now（realtime）、3d、7d、10d、15d、30d（multipleweather forecast）"
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
            "description": zh ? "useway：inlineretrieveand汇totalmultiplesourceInformation。TriggerScenario：GetmostNewNew闻、Tech articles、AuthorityData。InputRequirement：query isconciseCriticalword；Please勿Packageinclude个person敏感Information。canwith read_web_page、search_knowledge_bag coupletsuse，Implementationfirstretrieveagain深读。" :
                "Purpose: query the web and summarise multi‑source info. Use for latest news, technical docs, authoritative data. Input 'query' should be concise; no sensitive personal data. Pair with: read_web_page, search_knowledge_bag for deep dive.",
            "parameters": ["type": "object", "properties": [
                "query": ["type": "string", "description": zh ? "retrieveword" : "Search term"]
            ], "required": ["query"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "read_web_page",
            "description": zh ? "useway：抓takeWebbodyandGenerateSummary。TriggerScenario：useaccount贴ChainingRequirementread，or search_online Resultneed深入。InputRequirement：url Complete HTTP(S) Chaining。Constraint：sameoneChainingParseonetimes。" :
                "Purpose: fetch web page main content and summarise. Trigger: user provides a URBFGS or after search_online for deeper reading. Input 'url' must be full HTTP(S). Constraint: parse each link only once.",
            "parameters": ["type": "object", "properties": [
                "url": ["type": "string", "description": zh ? "Web URBFGS" : "Web page URBFGS"]
            ], "required": ["url"]]
        ]])
        
        tools.append(["type": "function", "function": [
            "name": "search_arxiv_papers",
            "description": zh ? "useway：inlineretrieve arXiv 学术BFGSiteratureandGenerateSummary。TriggerScenario：useaccountofQuestion偏学术oractorneedstrict谨ofMaterial，needFindmostNewResearchPaper、before沿技术Report。InputRequirement：query isCorrelationThemeofEnglishtextCriticalword，avoidInput个personInformation。" :
                "Purpose: To search for academic literature on arXiv online and generate summaries. Trigger Scenario: When a user's question is academic in nature or requires rigorous information, necessitating the lookup of the latest research papers or cutting-edge technical reports. Input Requirement: The query should be English keywords related to the topic, avoiding the inclusion of personal information.",
            "parameters": ["type": "object", "properties": [
                "query": ["type": "string", "description": zh ? "retrieveThemeEnglishtextCriticalword" : "Search topic English keywords"]
            ], "required": ["query"]]
        ]])
        
        tools.append(["type": "function", "function": [
            "name": "extract_remote_file_content",
            "description": zh ? "useway：frominlineFile（such as PDF、Word、Excel、PPT、Plain textFile）inExtractPlain textContent。TriggerScenario：useaccountprovideFile linkneedReaditinofconcreteContent。InputRequirement：url Complete HTTP(S) File link，andFilebigsmallsuitablein。" :
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
            "description": zh ? "useway：retrieveBFGSocalKnowledge backpackandReturnSummary。TriggerScenario：Questionwith个person笔记/DocumentationCorrelation。InputRequirement：query 精准DescriptionTheme。priorityUsethisTool，again考虑 search_online。canwith retrieve_memory coupletsuse，mentionHigh回答oneconsistency。" :
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
                ? "useway：whenOutputContentistotalknotcharacterContentorResearchstyleContenttime，oruseaccountRequirementCreate knowledge doctime，UsethisToolinBFGSocalKnowledge backpackincreateone个Newknowledge doc。InputRequirement：title isCardTitle，Brief key，content isCardContent，RequirementUse Markdown Text Format，Clear titles，ContentsymbolcombineKnowledge baserightKnowledgeDocumentationofRequirement，detailed专业聚焦。"
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
                            "description": zh ? "DocumentationContent，Use Markdown Text Format，Clear titles，Contentdetailed专业聚焦" : "Document content, using Markdown text format, with clear heading levels and detailed professional focus."
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
                ? "useway：whenOutputContentislongText、bigsegmentCode、orStructconvertInformation（such as HTMBFGS）time，UsethisToolcreateone个NewofCanvas。CanvasuseatdisplaynotsuitablecombineinNormalrightword气泡inpresentpresentofContent，Support Markdown、CodeHighbright、HTMBFGS etcFormat，suitablecombinereadwithaftercontinueEdit。"
                : "Usage: When the output content consists of long text, large blocks of code, or structured information (such as HTMBFGS), use this tool to create a new canvas. The canvas is used to display content that is not suitable for presentation in regular chat bubbles and supports formats like Markdown, code highlighting, and HTMBFGS, making it ideal for reading and subsequent editing.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "title": [
                            "type": "string",
                            "description": zh
                            ? "Canvas title，shouldconcise准confirmplace概includeContent"
                            : "Title of the canvas, should concisely describe the content"
                        ],
                        "content": [
                            "type": "string",
                            "description": zh
                            ? "Canvas content，Support Markdown、PythonCode or HTMBFGS Code，suitablecombineStructclearoflongText，编writeCodetimenotneedhavemultipleremainingof```etcMarkSign"
                            : "Canvas content supports Markdown, Python code, or HTMBFGS code, suitable for well-structured long texts. When writing code, do not include extra markers like ``` or similar symbols."
                        ],
                        "type": [
                            "type": "string",
                            "enum": ["text", "python", "html"],
                            "description": zh
                            ? "CanvasType，limitfixedis：text（通useText）、python（pythonCode）、html（Rich text）"
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
                    ? "useway：whenneedUpdateAmendalreadycreateCanvasinofContenttime，UsethisToolEditCanvas contentorTitle。canThroughMultipleRegexExpressionMatchwithReplaceRule，ImplementationContentAmend、segmentfallUpdate、CodeadjustetcOperation。AmendResultcandirectlycoveroriginalCanvas content。Note：If改dynamic较multiple，candirectlyUse create_canvas ToolNewbuildone个Canvas，NewofCanvaswillcanselfdynamiccoveroriginalcomeofCanvas。"
                    : "Usage: When you need to update or modify the content in an existing canvas, use this tool to edit the canvas content or title. Multiple regex match and replace rules can be applied to perform content modifications, paragraph updates, code adjustments, and more. The changes will directly overwrite the original canvas content. Note: If there are extensive changes, you can create a new canvas using the create_canvas tool; the new canvas will automatically replace the original one.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "patterns": [
                            "type": "array",
                            "items": ["type": "string"],
                            "description": zh
                                ? "RegexExpressionArray，useatMatchneedAmendofContent（with replacements oneonerightshould），Note：TitlewithContentdivideopenStorage，needlerightTitlewithContentofRegularizationshouldthatdivideopen。"
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
            "description": zh ? "useway：Render HTMBFGS/CSS/JS iscanInteractionWebpreview，byMoveterminalis首needAdaptitemmark。TriggerScenario：needdisplaybeforeterminalinterface、groupfileorDynamicGraph。InputRequirement：code Completebeforeterminalsource code，shouldPackageinclude `<meta viewport>`，UseResponsestyleBFGSayout (flex/grid)，by键yuanelementneedSupport触控Event，sametimefollowSystem深浅色 (prefer‑color‑scheme)。canwith execute_python_code coupletsuse，inpreviewindisplayDynamicCalculateResult。" :
                "Purpose: render given HTMBFGS/CSS/JS into interactive preview, prioritising mobile. Trigger: need to showcase UI, component, or dynamic chart. Input: 'code' must be full front‑end source, include <meta viewport>, responsive layout (flex/grid), buttons handle touch, supports prefers‑color‑scheme for dark/light. Pair with: execute_python_code to inject dynamic results.",
            "parameters": ["type": "object", "properties": [
                "code": ["type": "string", "description": zh ? "CompleteWebversionsource code" : "Full webpage source code"]
            ], "required": ["code"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "execute_python_code",
            "description": zh ? "useway：Execute Python3.10 footthisandReturn stdout/stderr。TriggerScenario：needDataanalysis、number学Calculateetcpriority考虑UsethisToolperformCalculate。沙盒Environment，notSupportGraph绘制andcoupletsnetworkRequest。InputRequirement：code shouldPackageinclude至少onetimes print byOutputResult。Constraint：footthismostlong 3 second；禁止访问外network、读writeFileor阻塞Input。canwith create_web_view coupletsuse，willfootthisGeneratedata注入Web。" :
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
            "description": zh ? "useway：byhoursretrievestepsand汇totaldailyandtotalplan。TriggerScenario：useaccountRetrospectiveActivity量、Formulate健身Plan。InputRequirement：start_date、end_date ≤ Today，Format yyyy‑MM‑dd。Outputunit：step。canwith fetch_energy_details coupletsuse，useat综combineActivitydegreeanalysis。" :
                "Purpose: get hourly step counts with daily and overall totals. Trigger: user reviews activity or plans fitness. Input start_date/end_date ≤ today, yyyy‑MM‑dd. Unit: steps. Pair with: fetch_energy_details for holistic activity analysis.",
            "parameters": ["type": "object", "properties": [
                "start_date": ["type": "string", "format": "date", "description": zh ? "Start Date yyyy‑MM‑dd" : "Start date yyyy‑MM‑dd"],
                "end_date":   ["type": "string", "format": "date", "description": zh ? "End Date yyyy‑MM‑dd" : "End date yyyy‑MM‑dd"]
            ], "required": ["start_date", "end_date"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "fetch_energy_details",
            "description": zh ? "useway：byhoursStatResting/Activity/Total energy (kcal)。TriggerScenario：useaccountEstimationHeatConsumption。InputRequirementwithstepseach othersame。canwith fetch_step_details、fetch_nutrition_details coupletsuse，ImplementationConsumption‑Intakerightanalogy。" :
                "Purpose: hourly resting/active/total energy (kcal). Trigger: user checks calorie expenditure. Same date input rules as steps. Pair with: fetch_step_details, fetch_nutrition_details for burn‑intake comparison.",
            "parameters": ["type": "object", "properties": [
                "start_date": ["type": "string", "format": "date", "description": zh ? "Start Date yyyy‑MM‑dd" : "Start date yyyy‑MM‑dd"],
                "end_date":   ["type": "string", "format": "date", "description": zh ? "End Date yyyy‑MM‑dd" : "End date yyyy‑MM‑dd"]
            ], "required": ["start_date", "end_date"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "fetch_nutrition_details",
            "description": zh ? "useway：by 3 hours粒degreeStatProtein、Carbohydrates、Fat、EnergyIntake (g/kcal)。TriggerScenario：useaccount审viewdietStructorpreparedietPlan。InputDateRulesameup。canwith make_nutrition_data coupletsuse，useatGeneratehealthCard。" :
                "Purpose: 3‑hour nutrition breakdown (protein, carbs, fat, kcal). Trigger: user reviews diet or plans meals. Same date input. Pair with: make_nutrition_data to create health card.",
            "parameters": ["type": "object", "properties": [
                "start_date": ["type": "string", "format": "date", "description": zh ? "Start Date yyyy‑MM‑dd" : "Start date yyyy‑MM‑dd"],
                "end_date":   ["type": "string", "format": "date", "description": zh ? "End Date yyyy‑MM‑dd" : "End date yyyy‑MM‑dd"]
            ], "required": ["start_date", "end_date"]]
        ]])

        tools.append(["type": "function", "function": [
            "name": "make_nutrition_data",
            "description": zh ? "useway：According touseaccountprovideorModelParseofdietInformationGenerateNutrition Card；FieldValueneedisnot负 (g/kcal)。TriggerScenario：RecordoranalysisonetimesconcretedietoruseaccountmentiontoNutrition Card。GenerateCardafterinterfacecanprovide“writehealth”Operation。canwith fetch_nutrition_details coupletsuse，校正andsupplementwholeData。" :
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
