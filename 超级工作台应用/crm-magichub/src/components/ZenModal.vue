<template>
  <dialog
    ref="dialogRef"
    :class="['p-0 border-0 rounded-3xl apple-glass shadow-2xl w-full outline-none backdrop:backdrop-blur-md backdrop:bg-zen-ink/15 transition-all duration-300', wide ? 'max-w-5xl' : 'max-w-xl']"
    @cancel="handleCancel"
    @click="handleBackdropClick"
  >
    <div class="p-8 flex flex-col font-sans text-zen-ink">
      <!-- Modal Header -->
      <div class="flex justify-between items-center mb-6">
        <h3 class="text-lg font-medium font-serif-sc text-zen-ink tracking-wide">
          {{ title }}
        </h3>
        <button
          @click="closeModal"
          class="w-8 h-8 rounded-full flex items-center justify-center text-zen-gray hover:text-zen-ink hover:bg-zen-light/40 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-zen-green/40"
          aria-label="关闭"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <!-- Modal Body -->
      <div class="flex-1 text-sm text-zen-gray leading-relaxed mb-6">
        <slot></slot>
      </div>

      <!-- Modal Footer -->
      <div class="flex justify-end gap-3 pt-2 border-t border-zen-light/30">
        <slot name="footer">
          <button
            @click="closeModal"
            class="px-5 py-2 rounded-lg border border-zen-light text-zen-gray text-xs hover:text-zen-ink hover:bg-zen-light/20 transition-all font-medium"
          >
            返回
          </button>
        </slot>
      </div>
    </div>
  </dialog>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue';

const props = defineProps({
  open: {
    type: Boolean,
    default: false
  },
  title: {
    type: String,
    default: ''
  },
  wide: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits(['close']);
const dialogRef = ref(null);

// Synchronize prop state with native dialog APIs
watch(() => props.open, (newVal) => {
  if (!dialogRef.value) return;
  if (newVal) {
    if (!dialogRef.value.open) {
      dialogRef.value.showModal();
    }
  } else {
    if (dialogRef.value.open) {
      dialogRef.value.close();
    }
  }
});

onMounted(() => {
  if (props.open && dialogRef.value && !dialogRef.value.open) {
    dialogRef.value.showModal();
  }
});

const closeModal = () => {
  emit('close');
};

const handleCancel = (e) => {
  e.preventDefault(); // Prevent closing by ESC natively to let parent manage state
  emit('close');
};

// Close modal when clicking the native backdrop layer
const handleBackdropClick = (e) => {
  if (e.target === dialogRef.value) {
    emit('close');
  }
};
</script>
