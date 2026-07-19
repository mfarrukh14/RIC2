using System.ComponentModel.DataAnnotations;

namespace InventoryManagement.Api.Validation
{
    // EmailAddressAttribute only treats null as valid; an empty/whitespace string
    // (which is what optional form fields submit) fails its regex and is rejected
    // even though the field isn't required. This variant also accepts blank values.
    // EmailAddressAttribute is sealed, so validation is delegated rather than inherited.
    public class OptionalEmailAddressAttribute : ValidationAttribute
    {
        private static readonly EmailAddressAttribute EmailValidator = new();

        public override bool IsValid(object? value)
        {
            if (value is string s && string.IsNullOrWhiteSpace(s))
                return true;

            return EmailValidator.IsValid(value);
        }
    }
}
