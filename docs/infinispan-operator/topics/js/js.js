$(document).ready(function() {
    var prefix = "/docs/";
    var path = document.location.pathname;
    var versionMatch = path.match(/^\/docs\/(\d+\.\d+\.x)\//);
    var version = versionMatch ? versionMatch[1] : null;

    // Inject collapsible sidebar styles
    $('head').append(
        '<style>' +
        '#toc-toggle { cursor: pointer; float: right; font-size: 1.2em; color: #7a2518; padding: 0.2em; }' +
        '#toc-toggle:hover { color: #ba3925; }' +
        'body.toc2.toc-collapsed { padding-left: 2.5em; }' +
        'body.toc2.toc-right.toc-collapsed { padding-left: 0; padding-right: 2.5em; }' +
        'body.toc-collapsed #toc.toc2 { width: 2.5em; padding: 0.5em 0.25em; }' +
        'body.toc-collapsed #toc.toc2 #tocheader a,' +
        'body.toc-collapsed #toc.toc2 #toctitle,' +
        'body.toc-collapsed #toc.toc2 #dchooser,' +
        'body.toc-collapsed #toc.toc2 #vchooser,' +
        'body.toc-collapsed #toc.toc2 #tocsearch,' +
        'body.toc-collapsed #toc.toc2 #toctreeexpand,' +
        'body.toc-collapsed #toc.toc2 #toctreecollapse,' +
        'body.toc-collapsed #toc.toc2 #toctree,' +
        'body.toc-collapsed #toc.toc2 hr { display: none; }' +
        'body.toc-collapsed #toc.toc2 #tocheader { text-align: center; margin: 0; padding: 0; }' +
        'body.toc-collapsed #toc.toc2 #toc-toggle { float: none; display: block; text-align: center; }' +
        '</style>'
    );

    // Sidebar toggle
    var canStore = false;
    try {
        var cookiePrefs = CookieConsent.getUserPreferences();
        canStore = cookiePrefs.acceptedCategories.includes("functionality");
    } catch(e) {}
    var collapsed = canStore && localStorage.getItem('toc-collapsed') === 'true';
    if (collapsed) {
        $('body').addClass('toc-collapsed');
    }

    $('#toctitle').before('<div id="tocheader"><span id="toc-toggle" title="Toggle sidebar"><i class="fa fa-chevron-left" aria-hidden="true"></i></span><a href="/documentation/"><img src="/assets/images/infinispan-logo.png" alt="Infinispan"></a></div>');

    $('#toc-toggle').click(function() {
        $('body').toggleClass('toc-collapsed');
        var isCollapsed = $('body').hasClass('toc-collapsed');
        $(this).find('i').toggleClass('fa-chevron-left', !isCollapsed).toggleClass('fa-chevron-right', isCollapsed);
        if (canStore) {
            localStorage.setItem('toc-collapsed', isCollapsed);
        }
    });
    if (collapsed) {
        $('#toc-toggle i').removeClass('fa-chevron-left').addClass('fa-chevron-right');
    }

    // Documentation chooser - populated from doc-index.json
    $('#toctitle').before('<select id="dchooser"></select>');
    var dchooser = $('#dchooser');
    dchooser.append('<option>Documentation index</option>');
    $.getJSON('/docs/doc-index.json', function(data) {
        $.each(data.categories, function(_, category) {
            var optgroup = $('<optgroup>', { label: category.name });
            $.each(category.titles, function(_, title) {
                optgroup.append($('<option>', { value: title.path, text: title.label }));
            });
            dchooser.append(optgroup);
        });
    });
    dchooser.change(function() {
        if (this.value !== '') {
            if (this.value.startsWith('https://')) {
                window.location.href = this.value;
            } else if (this.value.startsWith('/titles/') && version) {
                window.location.href = prefix + version + this.value;
            } else {
                window.location.href = this.value;
            }
        }
    });
    dchooser.after('<hr/>');

    // Version chooser - only on versioned core doc pages
    if (version) {
        $.ajax({type: 'GET', dataType: 'xml', url: '/docs/versions.xml',
                success: function(xml) {
                    $('#toctitle').before('<select id="vchooser"></select>');
                    var vchooser = $('#vchooser');
                    vchooser.append('<option>Choose version</option>');
                    $(xml).find('version').each(function() {
                        var name = $(this).attr("name");
                        var selected = name.indexOf(version) === 0 ? "selected" : "";
                        vchooser.append('<option value="' + $(this).attr("path") + '" ' + selected + '>' + name + '</option>');
                    });
                    vchooser.change(function() {
                        if (this.value !== '')
                            window.location.href = path.replace(version, this.value);
                    });
                    vchooser.after('<hr/>');
                }
        });
    }

    // TOC tree with jstree
    $('ul.sectlevel1').wrap('<div id="toctree"></div>');
    var plugins = [ "search", "wholerow" ];
    if (canStore) {
        plugins.push("state");
    }
    var toctree = $('#toctree');
    toctree.jstree({
        "core" : {
        "themes" : {"variant" : "small", "icons" : false}
    },
    "plugins" : plugins })
          .on("activate_node.jstree", function (e, data) { location.href = data.node.a_attr.href; });
    toctree.before('<input placeholder="&#xf002; Search" id="tocsearch" type="text">');
    var searchTimeout = false;
    var tocsearch = $('#tocsearch');
    tocsearch.keyup(function () {
        if(searchTimeout) { clearTimeout(searchTimeout); }
        searchTimeout = setTimeout(function () {
            var v = tocsearch.val();
            toctree.jstree(true).search(v);
        }, 250);
    });
    tocsearch.after('<a href="#" id="toctreeexpand" title="Expand"><i class="fa fa-plus-square" aria-hidden="true"></i></a><a href="#" id="toctreecollapse" title="Collapse"><i class="fa fa-minus-square" aria-hidden="true"></i></a>');
    $('#toctreeexpand').click(function() { $('#toctree').jstree('open_all'); });
    $('#toctreecollapse').click(function() { $('#toctree').jstree('close_all'); });
});
