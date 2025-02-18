$(function () {
    $('span').click(function () {
        $('#dataList li:hidden').show();
        if ($('#dataList li').length == $('#dataList li:visible').length) {
            $('span.show-all').hide();
        }
    });
});
