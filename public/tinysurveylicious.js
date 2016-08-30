/*
 * tinysurveylicious - a tiny web survey application
 * Copyright (C) Eskild Hustvedt 2016
 *
 * Javascript component
 */
$(function ()
{
    /*
     * Handles select-custom fields
     */
    $('select').change(function ()
    {
        var $this = $(this);
        var $textBox = $this.parent().find('.custom-text-input');
        var name = $this.attr('name').replace(/-custom$/,'');
        if($this.val() == '_custom_')
        {
            $this.attr('name',name+'-custom');
            $textBox.attr('name',name);
            $textBox.val('').prop('disabled', false).focus();
        }
        else
        {
            $this.attr('name',name);
            $textBox.attr('name',name+'-custom');
            $textBox.val($(this).val()).prop('disabled', true);
        }
    });
});
