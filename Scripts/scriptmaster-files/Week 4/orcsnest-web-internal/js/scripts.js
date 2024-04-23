/*!
* Start Bootstrap - Creative v7.0.7 (https://startbootstrap.com/theme/creative)
* Copyright 2013-2023 Start Bootstrap
* Licentie: MIT (https://github.com/StartBootstrap/startbootstrap-creative/blob/master/LICENSE)
*/
//
// Scripts
// 

// Wacht tot de DOM volledig is geladen
window.addEventListener('DOMContentLoaded', event => {

    // Functie voor het verkleinen van de navigatiebalk
    var verkleinNavigatie = function () {
        const navigatieBalk = document.body.querySelector('#mainNav');
        const faviconWrapper = document.getElementById('favicon-wrapper'); // Selecteer de wrapper van de afbeelding
        if (!navigatieBalk || !faviconWrapper) {
            return;
        }
        if (window.scrollY === 0) {
            navigatieBalk.classList.remove('navbar-shrink');
            faviconWrapper.style.display = 'none'; // Verberg de afbeelding wrapper als de navigatiebalk niet is verkleind
        } else {
            navigatieBalk.classList.add('navbar-shrink');
            faviconWrapper.style.display = 'block'; // Toon de afbeelding wrapper als de navigatiebalk is verkleind
        }
    };

    // Verklein de navigatiebalk bij het laden van de pagina
    verkleinNavigatie();

    // Verklein de navigatiebalk wanneer de pagina wordt gescrold
    document.addEventListener('scroll', verkleinNavigatie);

    // Activeer Bootstrap scrollspy op het hoofdnav-element
    const hoofdNav = document.body.querySelector('#mainNav');
    if (hoofdNav) {
        new bootstrap.ScrollSpy(document.body, {
            target: '#mainNav',
            rootMargin: '0px 0px -40%',
        });
    }

    // Sluit het responsieve menu ineen wanneer de toggler zichtbaar is
    const navbarToggler = document.body.querySelector('.navbar-toggler');
    const responsiveNavItems = [].slice.call(
        document.querySelectorAll('#navbarResponsive .nav-link')
    );
    responsiveNavItems.map(function (responsiveNavItem) {
        responsiveNavItem.addEventListener('click', () => {
            if (window.getComputedStyle(navbarToggler).display !== 'none') {
                navbarToggler.click();
            }
        });
    });

    // Activeer de SimpleLightbox-plugin voor portfoliostukken
    //new SimpleLightbox({
    //    elements: '#portfolio a.portfolio-box'
    //});

});
