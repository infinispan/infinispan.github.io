$(document).ready(function() {
  "use strict";
  var myNav = {
    init: function() {
      this.cacheDOM();
      this.browserWidth();
      this.bindEvents();
      this.bindDropdowns();
    },
    cacheDOM: function() {
      this.navToggle = $(".nav-toggle");
      this.chkBox = $("#checkbox");
      this.navMenu = $("#menu");
    },
    browserWidth: function() {
      $(window).resize(this.bindEvents.bind(this));
    },
    bindEvents: function() {
      var width = window.innerWidth;

      if (width < 1024) {
        this.navToggle.click(this.animate.bind(this));
        this.navMenu.hide();
        this.chkBox[0].checked = false;
      } else {
        this.resetNav();
      }
    },
    bindDropdowns: function() {
      $(".dropdown-toggle").on("click", function(e) {
        e.preventDefault();
        e.stopPropagation();
        var $parent = $(this).closest(".dropdown");
        var isOpen = $parent.hasClass("open");

        $(".dropdown").removeClass("open");
        $(".dropdown-toggle").attr("aria-expanded", "false");

        if (!isOpen) {
          $parent.addClass("open");
          $(this).attr("aria-expanded", "true");
        }
      });

      $(".dropdown-toggle").on("keydown", function(e) {
        if (e.key === "Escape") {
          $(this).closest(".dropdown").removeClass("open");
          $(this).attr("aria-expanded", "false");
          $(this).focus();
        }
      });

      $(".submenu a").on("keydown", function(e) {
        if (e.key === "Escape") {
          var $dropdown = $(this).closest(".dropdown");
          $dropdown.removeClass("open");
          $dropdown.find(".dropdown-toggle").attr("aria-expanded", "false").focus();
        }
      });

      $(document).on("click", function() {
        $(".dropdown").removeClass("open");
        $(".dropdown-toggle").attr("aria-expanded", "false");
      });
    },
    animate: function(e) {
      var checkbox = this.chkBox[0];
      !checkbox.checked ?
        this.navMenu.slideDown() :
        this.navMenu.slideUp();
    },
    resetNav: function() {
      this.navMenu.show();
    }
  };
  myNav.init();
});
