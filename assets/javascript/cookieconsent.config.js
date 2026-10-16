const CAT_NECESSARY = "necessary";
const CAT_ANALYTICS = "analytics";
const CAT_FUNCTIONALITY = "functionality";

const SERVICE_ANALYTICS_STORAGE = 'analytics_storage'
const SERVICE_FUNCTIONALITY_STORAGE = 'functionality_storage'
const SERVICE_PERSONALIZATION_STORAGE = 'personalization_storage'

window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}

gtag('consent', 'default', {
    [SERVICE_ANALYTICS_STORAGE]: 'denied',
    [SERVICE_FUNCTIONALITY_STORAGE]: 'denied',
    [SERVICE_PERSONALIZATION_STORAGE]: 'denied',
});

function updateConsent() {
    gtag('consent', 'update', {
        [SERVICE_ANALYTICS_STORAGE]: CookieConsent.acceptedService(SERVICE_ANALYTICS_STORAGE, CAT_ANALYTICS) ? 'granted' : 'denied',
        [SERVICE_FUNCTIONALITY_STORAGE]: CookieConsent.acceptedService(SERVICE_FUNCTIONALITY_STORAGE, CAT_FUNCTIONALITY) ? 'granted' : 'denied',
        [SERVICE_PERSONALIZATION_STORAGE]: CookieConsent.acceptedService(SERVICE_PERSONALIZATION_STORAGE, CAT_FUNCTIONALITY) ? 'granted' : 'denied'
    });
}

CookieConsent.run({
    // Trigger consent update when user choices change
    onFirstConsent: () => {
        updateConsent();
    },
    onConsent: () => {
        updateConsent();
    },
    onChange: () => {
        updateConsent();
    },

    // Configure categories and services
    categories: {
        [CAT_NECESSARY]: {
            enabled: true,  // this category is enabled by default
            readOnly: true,  // this category cannot be disabled
        },
        [CAT_ANALYTICS]: {
            autoClear: {
                cookies: [
                    {
                        name: /^_ga/,   // regex: match all cookies starting with '_ga'
                    },
                    {
                        name: '_gid',   // string: exact cookie name
                    }
                ]
            },
            services: {
                [SERVICE_ANALYTICS_STORAGE]: {
                    label: 'Enables storage (such as cookies) related to analytics e.g. visit duration.',
                }
            }
        },
        [CAT_FUNCTIONALITY]: {
            services: {
                [SERVICE_FUNCTIONALITY_STORAGE]: {
                    label: 'Enables storage that supports the functionality of the website.',
                },
            }
        }
    },

    language: {
        default: 'en',
        translations: {
            en: {
                consentModal: {
                    title: 'We use cookies',
                    description: 'This website uses essential cookies to ensure its proper operation and tracking cookies to understand how you interact with it. The latter will be set only after consent.',
                    acceptAllBtn: 'Accept all',
                    acceptNecessaryBtn: 'Reject all',
                    showPreferencesBtn: 'Manage Individual preferences'
                },
                preferencesModal: {
                    title: 'Manage cookie preferences',
                    acceptAllBtn: 'Accept all',
                    acceptNecessaryBtn: 'Reject all',
                    savePreferencesBtn: 'Accept current selection',
                    closeIconLabel: 'Close modal',
                    sections: [
                        {
                            title: "Cookie usage",
                            description: "We use cookies to ensure the basic functionalities of the website and to enhance your online experience."
                        },
                        {
                            title: "Strictly necessary cookies",
                            description: "This currently just includes the cookie used to store consent preferences.",
                            linkedCategory: CAT_NECESSARY,
                        },
                        {
                            title: "Analytics",
                            description: 'Cookies used for analytics help collect data that allows services to understand how users interact with a particular service.',
                            linkedCategory: CAT_ANALYTICS,
                            cookieTable: {
                                headers: {
                                    name: "Name",
                                    domain: "Service",
                                    description: "Description",
                                    expiration: "Expiration"
                                },
                                body: [
                                    {
                                        name: "_ga",
                                        domain: "Google Analytics",
                                        description: "Cookie set by <a href=\"https://business.safety.google/adscookies/\">Google Analytics</a>",
                                        expiration: "Expires after 12 days"
                                    },
                                    {
                                        name: "_gid",
                                        domain: "Google Analytics",
                                        description: "Cookie set by <a href=\"https://business.safety.google/adscookies/\">Google Analytics</a>",
                                        expiration: "Session"
                                    }
                                ]
                            }
                        },
                        {
                            title: 'Functionality',
                            description: 'Cookies used for functionality that enhances the use of the sites. Currently used to store the state of the documentation tree.',
                            linkedCategory: CAT_FUNCTIONALITY,
                        },
                        {
                            title: 'More information',
                            description: 'For any queries in relation to the policy on cookies and your choices, please <a href="https://infinispan.zulipchat.com">contact us</a>.'
                        }
                    ]
                }
            }
        }
    }
});
